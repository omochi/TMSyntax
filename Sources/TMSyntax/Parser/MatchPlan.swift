public enum MatchPlan : CustomStringConvertible {
    case matchRule(MatchRule)
    case beginRule(ScopeRule)
    case endPattern(
        pattern: RegexPattern,
        beginMatchResult: Regex.MatchResult?,
        beginLineIndex: Int?)
    
    public var description: String {
        switch self {
        case .matchRule(let rule):
            return "test: \(rule)"
        case .beginRule(let rule):
            return "begin test: \(rule)"
        case .endPattern(let pattern, _, _):
            return "end test: \(pattern)"
        }
    }
    
    public static func createBeginRule(_ rule: ScopeRule) -> MatchPlan {
        precondition(rule.begin != nil)
        return .beginRule(rule)
    }
    
    public static func createEndPattern(pattern: RegexPattern,
                                        beginMatchResult: Regex.MatchResult?,
                                        beginLineIndex: Int?) -> MatchPlan
    {
        return .endPattern(pattern: pattern,
                           beginMatchResult: beginMatchResult,
                           beginLineIndex: beginLineIndex)
    }
}

