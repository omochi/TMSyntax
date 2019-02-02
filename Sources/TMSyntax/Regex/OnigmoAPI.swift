import Foundation
import Onigmo

public struct OnigmoError : Swift.Error, CustomStringConvertible {
    public var status: Int
    public var message: String
    
    public init(status: Int, message: String) {
        self.status = status
        self.message = message
    }
    
    public init(status: CInt, errorInfo: UnsafeMutablePointer<OnigErrorInfo>) {
        var buf: [OnigUChar] = Array(repeating: 0, count: Int(ONIG_MAX_ERROR_MESSAGE_LEN))
        let ap: [CVarArg] = [errorInfo]
        let _: CInt = buf.withUnsafeMutableBufferPointer {
            (buf: inout UnsafeMutableBufferPointer<OnigUChar>) -> CInt in
            
            withVaList(ap) { (ap: CVaListPointer) -> CInt in
                onig_error_code_to_str_v(buf.baseAddress,
                                         OnigPosition(status),
                                         ap)
            }
        }
        
        let message: String = buf.withUnsafeBufferPointer {
            (buf: UnsafeBufferPointer<OnigUChar>) -> String in
            
            buf.withMemoryRebound(to: CChar.self) {
                (buf: UnsafeBufferPointer<CChar>) -> String in
            
                String(utf8String: buf.baseAddress!)!
            }
        }
        
        self.init(status: Int(status), message: message)
    }
    
    public var description: String {
        return "Onigmo error (\(message))"
    }
}

internal enum Onigmo {
    static let _initToken: Int = {
        onig_init()
        return 1
    }()
    
    static func initOnce() {
        _ = _initToken
    }
    
    static var utf16Encoding: OnigEncodingType = {
        if CFByteOrderGetCurrent() == CFByteOrderBigEndian.rawValue {
            return OnigEncodingUTF_16BE
        } else {
            return OnigEncodingUTF_16LE
        }
    }()
    static var utf8Encoding = OnigEncodingUTF_8
    static var defaultSyntax = OnigDefaultSyntax

    static func checkStatus(_ status: CInt,
                            errorInfo: UnsafeMutablePointer<OnigErrorInfo>) throws
    {
        if status == ONIG_NORMAL {
            return
        }
        
        throw OnigmoError(status: status, errorInfo: errorInfo)
    }
    
    static func new<S: StringProtocol>(pattern: S, options: UInt32) throws -> OnigRegex {
        initOnce()
        
        var onig: OnigRegex?

        var errorInfo = OnigErrorInfo()
        
        try pattern.withOnigUCharString { (pattern: UnsafeBufferPointer<OnigUChar>) in
            let patternStart = pattern.baseAddress!
            let patternEnd = patternStart.advanced(by: pattern.count - 1)
            let st = onig_new(&onig,
                              patternStart,
                              patternEnd,
                              options,
                              &utf8Encoding,
                              defaultSyntax,
                              &errorInfo)
            try checkStatus(st, errorInfo: &errorInfo)
        }
        
        return onig!
    }
    
    static func free(regex: OnigRegex) {
        onig_free(regex)
    }
    
    static func search<S>(regex: OnigRegex,
                          string: S,
                          stringRange: Range<S.Index>,
                          searchRange: Range<S.Index>,
                          globalPosition: S.Index?)
        -> [Range<S.Index>?]?
        where S : StringProtocol,
        S.UTF8View.Index == S.Index
    {
        let u8 = string.utf8
        
        let stringRangeStartOffset = u8.distance(from: string.startIndex, to: stringRange.lowerBound)
        let stringRangeEndOffset = u8.distance(from: string.startIndex, to: stringRange.upperBound)
        let searchRangeStartOffset = u8.distance(from: string.startIndex, to: searchRange.lowerBound)
        let searchRangeEndOffset = u8.distance(from: string.startIndex, to: searchRange.upperBound)
        let globalPositionOffset = globalPosition.map {
            u8.distance(from: string.startIndex, to: $0)
        }
            
        var regionPointer = onig_region_new()!
        defer {
            onig_region_free(regionPointer, 1)
        }
        
        let options: OnigOptionType = ONIG_OPTION_NONE
        
        let ranges: [Range<S.Index>?]? = string.withOnigUCharString {
            (stringBuffer: UnsafeBufferPointer<OnigUChar>) in
            let stringBasePointer = stringBuffer.baseAddress!
            let stringStartPointer = stringBasePointer.advanced(by: stringRangeStartOffset)
            let stringEndPointer = stringBasePointer.advanced(by: stringRangeEndOffset)
            let searchRangeStartPointer = stringBasePointer.advanced(by: searchRangeStartOffset)
            let searchRangeEndPointer = stringBasePointer.advanced(by: searchRangeEndOffset)
        
            let pos: OnigPosition
            
            if let globalPositionOffset = globalPositionOffset {
                let globalPositionPointer = stringBasePointer.advanced(by: globalPositionOffset)
                
                pos = onig_search_gpos(regex,
                                       stringStartPointer,
                                       stringEndPointer,
                                       globalPositionPointer,
                                       searchRangeStartPointer,
                                       searchRangeEndPointer,
                                       regionPointer,
                                       options)
                
            } else {
                pos = onig_search(regex,
                                  stringStartPointer,
                                  stringEndPointer,
                                  searchRangeStartPointer,
                                  searchRangeEndPointer,
                                  regionPointer,
                                  options)
            }
            
            if pos < 0 {
                return nil
            }
            
            return regionToRange(regionPointer,
                                 string: string,
                                 stringRange: stringRange)
        }
        
        return ranges
    }
    
    static func regionToRange<S>(_ region: UnsafePointer<OnigRegion>,
                                 string: S,
                                 stringRange: Range<S.Index>)
        -> [Range<S.Index>?]
        where S : StringProtocol,
        S.UTF8View.Index == S.Index
    {
        let u8 = string.utf8
        
        var ranges: [Range<S.Index>?] = []
        
        let num = Int(region.pointee.num_regs)
        var startOffsetPointer = region.pointee.beg!
        var endOffsetPointer = region.pointee.end!
        
        for _ in 0..<num {
            let startOffset = Int(startOffsetPointer.pointee)
            let endOffset = Int(endOffsetPointer.pointee)
            if startOffset != ONIG_REGION_NOTPOS &&
                endOffset != ONIG_REGION_NOTPOS
            {
                // resolve string range offset
                let start = u8.index(stringRange.lowerBound, offsetBy: startOffset)
                let end = u8.index(stringRange.lowerBound, offsetBy: endOffset)
                
                ranges.append(start..<end)
            } else {
                ranges.append(nil)
            }
            
            startOffsetPointer = startOffsetPointer.advanced(by: 1)
            endOffsetPointer = endOffsetPointer.advanced(by: 1)
        }
        
        return ranges
    }
    
    static func region_new() -> UnsafeMutablePointer<OnigRegion> {
        return onig_region_new()
    }
    
    static func region_free(region: UnsafeMutablePointer<OnigRegion>) {
        onig_region_free(region, 1)
    }
}

internal extension StringProtocol {
    func withOnigUCharString<R>(_ f: (UnsafeBufferPointer<OnigUChar>) throws -> R) rethrows -> R {
        let count = self.utf8.count + 1 // null
        return try self.withCString{ (pointer: UnsafePointer<CChar>) -> R in
            return try pointer.withMemoryRebound(to: OnigUChar.self, capacity: count) {
                (pointer: UnsafePointer<OnigUChar>) -> R in
                return try f(UnsafeBufferPointer(start: pointer, count: count))
            }
        }
    }
}
