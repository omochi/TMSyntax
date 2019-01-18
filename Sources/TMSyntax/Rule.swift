import Foundation

public class Rule : CopyInitializable, Decodable {
    public enum Switcher {
        case scope(ScopeRule)
        case match(MatchRule)
        case include(IncludeRule)
    }
    
    public var switcher: Switcher {
        switch self {
        case let r as ScopeRule: return .scope(r)
        case let r as MatchRule: return .match(r)
        case let r as IncludeRule: return .include(r)
        default: fatalError("invalid subtype")
        }
    }

    public init() {}
    
    public enum CodingKeys : String, CodingKey {
        case patterns
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        self.init(copy: ScopeRule(patterns: []))
    }
}

