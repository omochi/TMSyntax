import Onigmo

public struct Regex {
    internal class Object {
        public let onig: OnigRegex
        
        public init(pattern: String, options: CompileOptions) throws {
            self.onig = try Onigmo.new(pattern: pattern,
                                       options: options.rawValue)
        }
        
        deinit {
            Onigmo.free(regex: onig)
        }
    }
    
    internal class _Region {
        public let region: UnsafeMutablePointer<OnigRegion>
        
        public init() {
            self.region = Onigmo.region_new()
        }
        
        deinit {
            Onigmo.region_free(region: region)
        }
    }
    
    public struct CompileOptions : OptionSet {
        public var rawValue: UInt32
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static var singleLine: CompileOptions {
            return CompileOptions(rawValue: ONIG_OPTION_SINGLELINE)
        }
        
        public static var dotAll: CompileOptions {
            return CompileOptions(rawValue: ONIG_OPTION_DOTALL)
        }
        
        public static var ignoreCase: CompileOptions {
            return CompileOptions(rawValue: ONIG_OPTION_IGNORECASE)
        }
        
        public static var extend: CompileOptions {
            return CompileOptions(rawValue: ONIG_OPTION_EXTEND)
        }
        
        public static var dontCaptureGroup: CompileOptions {
            return CompileOptions(rawValue: ONIG_OPTION_DONT_CAPTURE_GROUP)
        }
        
        public static var captureGroup: CompileOptions {
            return CompileOptions(rawValue: ONIG_OPTION_CAPTURE_GROUP)
        }
    }
    
    public struct SearchOptions : OptionSet {
        public var rawValue: UInt32
        
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public static var notBeginOfLine: SearchOptions {
            return SearchOptions(rawValue: ONIG_OPTION_NOTBOL)
        }
        
        public static var notEndOfLine: SearchOptions {
            return SearchOptions(rawValue: ONIG_OPTION_NOTEOL)
        }
        
        public static var notBeginOfString: SearchOptions {
            return SearchOptions(rawValue: ONIG_OPTION_NOTBOS)
        }
        
        public static var notEndOfString: SearchOptions {
            return SearchOptions(rawValue: ONIG_OPTION_NOTEOS)
        }
    }
    
    public struct MatchResult {
        public var ranges: [Range<String.Index>?]
        
        public init(ranges: [Range<String.Index>?]) {
            self.ranges = ranges
        }
        
        public subscript() -> Range<String.Index> {
            return ranges[0]!
        }
        
        public subscript(index: Int) -> Range<String.Index>? {
            guard 0 <= index && index < ranges.count else {
                return nil
            }
            return ranges[index]
        }
        
        public var count: Int { return ranges.count }
    }
    
    public init(pattern: String, options: CompileOptions) throws {
        self.object = try Object(pattern: pattern,
                                 options: options)
    }
    
    private let object: Object
    
    public func search<S>(string: S,
                          range: Range<S.Index>,
                          globalPosition: S.Index? = nil,
                          options: SearchOptions)
        -> MatchResult?
        where S : StringProtocol,
        S.Index == String.Index,
        S.UTF8View.Index == S.Index
    {
        guard let ranges = Onigmo.search(regex: object.onig,
                                         string: string,
                                         searchRange: range,
                                         globalPosition: globalPosition,
                                         options: options.rawValue) else
        {
            return nil
        }
        
        return MatchResult(ranges: ranges)
    }
    
    public func replace<S>(string: S,
                           replacer: (Regex.MatchResult) throws -> String)
        rethrows -> String
        where S : StringProtocol,
        S.Index == String.Index,
        S.UTF8View.Index == S.Index
    {
        var result = ""
        var pos = string.startIndex
        var globalPosition: String.Index? = nil
        while true {
            guard let match = search(string: string,
                                     range: pos..<string.endIndex,
                                     globalPosition: globalPosition,
                                     options: []) else {
                break
            }
            
            result.append(String(string[pos..<match[].lowerBound]))
            
            let rep = try replacer(match)
            result.append(rep)
            
            pos = match[].upperBound
            globalPosition = match[].lowerBound
        }
        result.append(String(string[pos...]))
        
        return result
    }
    
    public static let metaCharRegex: Regex =
        try! Regex(pattern: "[b-bbb{b}b*b+b?b|b^b$b.b,b[b]b(b)b#bs]"
            .replacingOccurrences(of: "b", with: "\\"), options: [])
    
    public static func escape(_ string: String) -> String {
        return metaCharRegex.replace(string: string) { (match) -> String in
            return "\\" + String(string[match[]])
        }
    }
}


