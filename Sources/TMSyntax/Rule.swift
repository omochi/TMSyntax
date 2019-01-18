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
    
    public weak var parent: Rule?
    
    public var repository: RuleRepository? {
        return nil
    }

    public init() {}
    
    public enum CodingKeys : String, CodingKey {
        case include
        case match
        case name
        case patterns
        case repository
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        if let includeStr = try c.decodeIfPresent(String.self, forKey: .include) {
            guard let include = IncludeTarget(includeStr) else {
                throw DecodingError(location: decoder.sourceLocation!,
                                    message: "invalid include (\(includeStr))")
            }
            self.init(copy: IncludeRule(include: include))
            return
        }
        
        if let matchStr = try c.decodeIfPresent(String.self, forKey: .match) {
            let scopeName = try c.decode(ScopeName.self, forKey: .name)
            
            self.init(copy: MatchRule(match: matchStr, scopeName: scopeName))
            return
        }
        
        let patterns = try c.decodeIfPresent([Rule].self, forKey: .patterns) ?? []
        let repository = try c.decodeIfPresent(RuleRepository.self, forKey: .repository)

        self.init(copy: ScopeRule(patterns: patterns,
                                  repository: repository))
    }
    
    public func rule(with name: String) -> Rule? {
        var ruleOrNone: Rule? = self
        while let rule = ruleOrNone {
            if let hit = rule.repository?.dict[name] {
                return hit
            }
            ruleOrNone = rule.parent
        }
        return nil
    }
}

