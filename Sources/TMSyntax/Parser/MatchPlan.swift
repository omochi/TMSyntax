public struct MatchPlan : CustomStringConvertible {
    public enum Pattern {
        case match(MatchRule)
        case begin(ScopeRule)
        case endPattern(
            pattern: RegexPattern,
            beginMatchResult: Regex.MatchResult?,
            beginLineIndex: Int?)
        
        public var description: String {
            switch self {
            case .match(let rule):
                return "test: \(rule)"
            case .begin(let rule):
                return "begin test: \(rule)"
            case .endPattern(let pattern, _, _):
                return "end test: \(pattern)"
            }
        }
    }

    public var position: ScopeMatchPosition
    public var pattern: Pattern
    
    public init(position: ScopeMatchPosition,
                pattern: Pattern)
    {
        self.pattern = pattern
        self.position = position
    }
    
    public var description: String {
        var d = pattern.description
        
        switch position {
        case .none: break
        case .left: d = "L:" + d
        case .right: d = "R:" + d
        }
        
        return d
    }
    
    public static func createMatchRule(position: ScopeMatchPosition,
                                       rule: MatchRule) -> MatchPlan
    {
        return MatchPlan(position: position, pattern: .match(rule))
    }
    
    public static func createBeginRule(position: ScopeMatchPosition,
                                       rule: ScopeRule) -> MatchPlan
    {
        precondition(rule.begin != nil)
        return MatchPlan(position: position, pattern: .begin(rule))
    }
    
    public static func createEndPattern(pattern: RegexPattern,
                                        beginMatchResult: Regex.MatchResult?,
                                        beginLineIndex: Int?) -> MatchPlan
    {
        return MatchPlan(position: .none,
                          pattern: .endPattern(pattern: pattern,
                                               beginMatchResult: beginMatchResult,
                                               beginLineIndex: beginLineIndex))
    }
}

