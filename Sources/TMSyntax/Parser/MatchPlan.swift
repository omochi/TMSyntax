public enum MatchPlan : CustomStringConvertible {
    case matchRule(MatchRule)
    case beginRule(ScopeRule, BeginEndCondition)
    case endRule(ScopeRule, BeginEndCondition, RegexPattern)
    
    public var pattern: RegexPattern {
        switch self {
        case .matchRule(let rule):
            return rule.pattern
        case .beginRule(_, let cond):
            return cond.begin
        case .endRule(_, _, let pattern):
            return pattern
        }
    }
    
    public var description: String {
        switch self {
        case .matchRule(let rule):
            return "test: \(rule)"
        case .beginRule(let rule):
            return "begin test: \(rule)"
        case .endRule(let rule, _, _):
            return "end test: \(rule)"
        }
    }
}

