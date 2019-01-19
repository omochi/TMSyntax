import Onigmo

public struct Regex {
    internal class Object {
        public let onig: OnigRegex
        
        public init(pattern: String) throws {
            self.onig = try Onigmo.new(pattern: pattern)
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
    
    public struct Match {
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
    }
    
    public init(pattern: String) throws {
        self.object = try Object(pattern: pattern)
    }
    
    private let object: Object
    
    public func search(string: String, range: Range<String.Index>) -> Match? {
        guard let ranges = Onigmo.search(regex: object.onig,
                                         string: string,
                                         range: range) else
        {
            return nil
        }
        
        return Match(ranges: ranges)
    }
    
    public func replace(string: String, replacer: (Regex.Match) -> String) -> String {
        var result = ""
        var pos = string.startIndex
        while true {
            guard let match = search(string: string, range: pos..<string.endIndex) else {
                break
            }
            
            result.append(String(string[pos..<match[].lowerBound]))
            
            let rep = replacer(match)
            result.append(rep)
            
            pos = match[].upperBound
        }
        result.append(String(string[pos...]))
        
        return result
    }
}


