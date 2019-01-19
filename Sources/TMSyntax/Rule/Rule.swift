import Foundation
import RichJSONParser

public class Rule : CopyInitializable, Decodable, CustomStringConvertible {
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
    
    public var name: String?
    public weak var parent: Rule?
    
    public var repository: RuleRepository? { return nil }
    public var scopeName: ScopeName? { return nil }

    public let sourceLocation: SourceLocation?
    
    public init(sourceLocation: SourceLocation?) {
        self.sourceLocation = sourceLocation
    }
    
    public var description: String {
        var d = ""
        
        if let name = name {
            d += "[\(name)] "
        } else {
            d += "[--] "
        }
        
        switch switcher {
        case .include(let rule):
            d += "include rule (\(rule.target))"
        case .match(let rule):
            d += "match rule \(rule.pattern)"
        case .scope(let rule):
            switch rule.condition {
            case .beginEnd(let cond):
                d += "begin end rule \(cond.begin)"
            case .none:
                d += "scope rule"
            }
        }
        
        if let loc = sourceLocation {
            d += " at \(loc)"
        }
        
        return d
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
        
        if let target = try c.decodeIfPresent(IncludeTarget.self, forKey: .include) {
            self.init(copy: IncludeRule(sourceLocation: decoder.sourceLocation,
                                        target: target))
            return
        }
        
        let scopeName = try c.decodeIfPresent(ScopeName.self, forKey: .name)
        
        if let matchPattern = try c.decodeIfPresent(RegexPattern.self, forKey: .match) {
            guard let scopeName = scopeName else {
                throw DecodingError(location: loc, "name not found in match rule")
            }
            
            self.init(copy: MatchRule(sourceLocation: decoder.sourceLocation,
                                      pattern: matchPattern,
                                      scopeName: scopeName))
            return
        }
        
        let patterns = try c.decodeIfPresent([Rule].self, forKey: .patterns) ?? []
        let repository = try c.decodeIfPresent(RuleRepository.self, forKey: .repository)
        
        if let beginPattern = try c.decodeIfPresent(RegexPattern.self, forKey: .begin) {
            guard let endPattern = try c.decodeIfPresent(RegexPattern.self, forKey: .end) else {
                throw DecodingError(location: loc, "end not found in begin rule")
            }
            
            let cond = BeginEndCondition(begin: beginPattern,
                                         end: endPattern)
            
            self.init(copy: ScopeRule(sourceLocation: decoder.sourceLocation,
                                      condition: .beginEnd(cond),
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
    
    public func collectEnterMatchPlans() -> [MatchPlan] {
        switch switcher {
        case .include(let rule):
            guard let target = rule.targetRule else {
                return []
            }
            return target.collectEnterMatchPlans()
        case .match(let rule):
            return [MatchPlan.matchRule(rule)]
        case .scope(let rule):
            switch rule.condition {
            case .beginEnd(let cond):
                return [MatchPlan.beginRule(rule, cond)]
            case .none:
                var plans: [MatchPlan] = []
                for e in rule.patterns {
                    plans += e.collectEnterMatchPlans()
                }
                return plans
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

