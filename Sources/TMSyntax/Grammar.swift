import Foundation
import FineJSON

public final class Grammer : Decodable, CopyInitializable {
    public let name: String
    public let scopeName: ScopeName
    public let rule: ScopeRule
    
    public enum CodingKeys : String, CodingKey {
        case name
        case scopeName
        case patterns
    }
    
    public convenience init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }
    
    public convenience init(data: Data) throws {
        let decoder = FineJSONDecoder()
        let copy = try decoder.decode(Grammer.self, from: data)
        self.init(copy: copy)
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try c.decode(String.self, forKey: .name)
        self.scopeName = try c.decode(ScopeName.self, forKey: .scopeName)
        
        let patterns: [Rule] = try c.decode([Rule].self, forKey: .patterns)
        
        self.rule = ScopeRule(patterns: patterns)
    }
}
