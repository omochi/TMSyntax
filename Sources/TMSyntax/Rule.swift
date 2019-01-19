import Foundation
import RichJSONParser

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

    public let sourceLocation: SourceLocation?
    
    public init(sourceLocation: SourceLocation?) {
        self.sourceLocation = sourceLocation
    }
    
    public enum CodingKeys : String, CodingKey {
        case include
        case match
        case name
        case patterns
        case repository
        case begin
        case end
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let loc = decoder.sourceLocation!
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        if let includeStr = try c.decodeIfPresent(String.self, forKey: .include) {
            guard let include = IncludeTarget(includeStr) else {
                throw DecodingError(location: loc, "invalid include (\(includeStr))")
            }
            self.init(copy: IncludeRule(sourceLocation: decoder.sourceLocation,
                                        include: include))
            return
        }
        
        let scopeName = try c.decodeIfPresent(ScopeName.self, forKey: .name)
        
        if let matchStr = try c.decodeIfPresent(String.self, forKey: .match) {
            guard let scopeName = scopeName else {
                throw DecodingError(location: loc, "name not found in match rule")
            }
            
            self.init(copy: MatchRule(sourceLocation: decoder.sourceLocation,
                                      match: matchStr, scopeName: scopeName))
            return
        }
        
        let patterns = try c.decodeIfPresent([Rule].self, forKey: .patterns) ?? []
        let repository = try c.decodeIfPresent(RuleRepository.self, forKey: .repository)
        
        if let beginStr = try c.decodeIfPresent(String.self, forKey: .begin) {
            guard let endStr = try c.decodeIfPresent(String.self, forKey: .end) else {
                throw DecodingError(location: loc, "end not found in begin rule")
            }
            
            self.init(copy: ScopeRule(sourceLocation: decoder.sourceLocation,
                                      condition: .beginEnd(BeginEndCondition(begin: beginStr,
                                                                             end: endStr)),
                                      patterns: patterns,
                                      repository: repository,
                                      scopeName: scopeName))
            return
        }
        
        self.init(copy: ScopeRule(sourceLocation: decoder.sourceLocation,
                                  condition: .none,
                                  patterns: patterns,
                                  repository: repository,
                                  scopeName: nil))
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
    
    // TODO: end match
    public func collectMatchPlans() -> [MatchPlan] {
        switch switcher {
        case .include(let rule):
            guard let target = rule.target else {
                return []
            }
            return target.collectMatchPlans()
        case .match(let rule):
            return [MatchPlan.matchRule(rule)]
        case .scope(let rule):
            switch rule.condition {
            case .beginEnd(let cond):
                return [MatchPlan.beginRule(rule, cond)]
            case .none:
                var result = [MatchPlan]()
                for e in rule.patterns {
                    result += e.collectMatchPlans()
                }
                return result
            }
        }
    }
    
    internal func _compileRegex(pattern: String) throws -> Regex {
        do {
            return try Regex(pattern: pattern)
        } catch {
            throw RegexCompileError(location: sourceLocation, error: error)
        }
    }
    
    internal var locationForDescription: String {
        if let loc = sourceLocation {
            return " at \(loc)"
        } else {
            return ""
        }
    }
}

