public enum MatchPlan : CustomStringConvertible {
    case matchRule(MatchRule)
    case beginRule(ScopeRule)
    case endPattern(RegexPattern)
    
    public var pattern: RegexPattern {
        switch self {
        case .matchRule(let rule):
            return rule.pattern
        case .beginRule(let rule):
            return rule.begin!
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
    
    public static func createBeginRule(_ rule: ScopeRule) -> MatchPlan {
        precondition(rule.begin != nil)
        return .beginRule(rule)
    }
}

