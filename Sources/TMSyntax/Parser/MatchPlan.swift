public enum MatchPlan : CustomStringConvertible {
    case matchRule(MatchRule)
    case beginRule(ScopeRule)
    case beginPositionRule(ScopeRule)
    case endRule(Rule, RegexPattern)
    
    public var pattern: RegexPattern? {
        switch self {
        case .matchRule(let rule):
            return rule.pattern
        case .beginRule(let rule):
            return rule.begin!
        case .beginPositionRule:
            return nil
        case .endRule(_, let pattern):
            return pattern
        }
    }
    
    public var beginPosition: String.Index? {
        switch self {
        case .matchRule,
             .beginRule,
             .endRule:
            return nil
        case .beginPositionRule(let rule):
            return rule.beginPosition!
        }
    }
    
    public var description: String {
        switch self {
        case .matchRule(let rule):
            return "test: \(rule)"
        case .beginRule(let rule):
            return "begin test: \(rule)"
        case .beginPositionRule(let rule):
            return "begin position test: \(rule)"
        case .endRule(let rule, _):
            return "end test: \(rule)"
        }
    }
    
    public static func createMatch(rule: MatchRule) -> MatchPlan {
        return .matchRule(rule)
    }
    
    public static func createBegin(rule: ScopeRule) -> MatchPlan {
        precondition(rule.begin != nil)
        return .beginRule(rule)
    }
    
    public static func createBeginPosition(rule: ScopeRule) -> MatchPlan {
        precondition(rule.beginPosition != nil)
        return .beginPositionRule(rule)
    }
    
    public static func createEnd(rule: Rule, pattern: RegexPattern) -> MatchPlan {
        return .endRule(rule, pattern)
    }
}

