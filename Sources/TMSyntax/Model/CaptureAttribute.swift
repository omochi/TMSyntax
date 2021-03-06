import Foundation
import RichJSONParser

public struct CaptureAttribute : Decodable {
    public var sourceLocation: SourceLocation?
    public var name: ScopeName?
    public var patterns: [Rule]
    
    public enum CodingKeys : String, CodingKey {
        case name
        case patterns
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        self.sourceLocation = decoder.sourceLocation
        self.name = try c.decodeIfPresent(ScopeName.self, forKey: .name)
        self.patterns = try c.decodeIfPresent([Rule].self, forKey: .patterns) ?? []
        
        if patterns.count > 0 {
            
        }
    }
    
    public init(sourceLocation: SourceLocation?,
                name: ScopeName?,
                patterns: [Rule])
    {
        self.sourceLocation = sourceLocation
        self.name = name
        self.patterns = patterns
    }
    
    public func resolveName(line: String,
                            matchResult: Regex.MatchResult) throws -> ScopeName?
    {
        return try BeginEndRule.resolveNameOptional(name: name,
                                                    line: line,
                                                    matchResult: matchResult)
    }
}
