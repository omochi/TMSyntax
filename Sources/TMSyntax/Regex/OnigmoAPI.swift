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
    
    static func new(pattern: String, options: UInt32) throws -> OnigRegex {
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
    
    static func search(regex: OnigRegex,
                       string: String,
                       range: Range<String.Index>,
                       globalPosition: String.Index?)
        -> [Range<String.Index>?]?
    {
        let u8 = string.utf8
        
        let rangeStartOffset = u8.distance(from: string.startIndex, to: range.lowerBound)
        let rangeEndOffset = u8.distance(from: string.startIndex, to: range.upperBound)
        
        var regionPointer = onig_region_new()!
        defer {
            onig_region_free(regionPointer, 1)
        }
        
        let options: OnigOptionType = ONIG_OPTION_NONE
        
        let ranges: [Range<String.Index>?]? = string.withOnigUCharString {
            (stringBuffer: UnsafeBufferPointer<OnigUChar>) in
            let stringStartPointer = stringBuffer.baseAddress!
            let stringEndPointer = stringStartPointer.advanced(by: stringBuffer.count - 1)
            let rangeStartPointer = stringStartPointer.advanced(by: rangeStartOffset)
            let rangeEndPointer = stringStartPointer.advanced(by: rangeEndOffset)
            
            let pos: OnigPosition
            
            if let globalPosition = globalPosition {
                let globalPositionOffset = u8.distance(from: string.startIndex, to: globalPosition)
                let globalPositionPointer = stringStartPointer.advanced(by: globalPositionOffset)
                
                pos = onig_search_gpos(regex,
                                       stringStartPointer,
                                       stringEndPointer,
                                       globalPositionPointer,
                                       rangeStartPointer,
                                       rangeEndPointer,
                                       regionPointer,
                                       options)
                
            } else {
                pos = onig_search(regex,
                                  stringStartPointer,
                                  stringEndPointer,
                                  rangeStartPointer,
                                  rangeEndPointer,
                                  regionPointer,
                                  options)
            }
            
            if pos < 0 {
                return nil
            }
            
            return regionToRange(regionPointer, utf8View: u8)
        }
        
        return ranges
    }

    static func regionToRange(_ region: UnsafePointer<OnigRegion>,
                              utf8View u8: String.UTF8View) -> [Range<String.Index>?]
    {
        var ranges: [Range<String.Index>?] = []
        
        let num = Int(region.pointee.num_regs)
        var startOffsetPointer = region.pointee.beg!
        var endOffsetPointer = region.pointee.end!
        
        for _ in 0..<num {
            let startOffset = Int(startOffsetPointer.pointee)
            let endOffset = Int(endOffsetPointer.pointee)
            if startOffset != ONIG_REGION_NOTPOS &&
                endOffset != ONIG_REGION_NOTPOS
            {
                let start = u8.index(u8.startIndex, offsetBy: startOffset)
                let end = u8.index(u8.startIndex, offsetBy: endOffset)
                
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

internal extension String {
    func withOnigUCharString<R>(_ f: (UnsafeBufferPointer<OnigUChar>) throws -> R) rethrows -> R {
        return try self.utf8CString.withUnsafeBufferPointer { (buf: UnsafeBufferPointer<CChar>) -> R in
            return try buf.withMemoryRebound(to: OnigUChar.self) { (buf: UnsafeBufferPointer<OnigUChar>) -> R in
                return try f(buf)
            }
        }
    }
}
