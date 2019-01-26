public enum MatchPlan : CustomStringConvertible {
    case matchRule(MatchRule)
    case beginRule(ScopeRule, RegexPattern)
    case endPattern(RegexPattern)
    
    public var pattern: RegexPattern {
        switch self {
        case .matchRule(let rule):
            return rule.pattern
        case .beginRule(_, let pattern):
            return pattern
        case .endPattern(let pattern):
            return pattern
        }
    }
    
    public var description: String {
        switch self {
        case .matchRule(let rule):
            return "test: \(rule)"
        case .beginRule(let rule):
            return "begin test: \(rule)"
        case .endPattern(let pattern):
            return "end test: \(pattern)"
        }
    }
}

