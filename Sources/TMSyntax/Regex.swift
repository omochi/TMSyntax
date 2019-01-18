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
        public var ranges: [Range<String.Index>]
        
        public init(ranges: [Range<String.Index>]) {
            self.ranges = ranges
        }
        
        internal init(region: _Region, string: String) {
            let u8 = string.utf8
            
            var ranges: [Range<String.Index>] = []
            
            var startPointer = region.region.pointee.beg!
            var endPointer = region.region.pointee.end!
            for _ in 0..<Int(region.region.pointee.num_regs) {
                let rangeStart = u8.index(u8.startIndex, offsetBy: Int(startPointer.pointee))
                let rangeEnd = u8.index(u8.startIndex, offsetBy: Int(endPointer.pointee))
                
                ranges.append(rangeStart..<rangeEnd)
                
                startPointer = startPointer.advanced(by: 1)
                endPointer = endPointer.advanced(by: 1)
            }
            
            self.init(ranges: ranges)
        }
        
        public subscript(index: Int) -> Range<String.Index> {
            return ranges[index]
        }
    }
    
    public init(pattern: String) throws {
        self.object = try Object(pattern: pattern)
    }
    
    private let object: Object
    
    public func search(string: String, range: Range<String.Index>) -> Match? {
        let region = _Region()
        
        guard let _ = Onigmo.search(regex: object.onig,
                                        string: string,
                                        range: range,
                                        region: region.region) else
        {
            return nil
        }
        
        return Match(region: region, string: string)
    }

}
