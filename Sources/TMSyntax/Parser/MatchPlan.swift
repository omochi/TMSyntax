public struct MatchPlan : CustomStringConvertible {
    public enum Pattern {
        case match(MatchRule)
        case beginEnd(BeginEndRule)
        case endPattern(
            pattern: RegexPattern,
            beginMatchResult: Regex.MatchResult?,
            beginLineIndex: Int?)
        case beginWhile(BeginWhileRule)
        
        public var description: String {
            switch self {
            case .match(let rule):
                return "test: \(rule)"
            case .beginEnd(let rule):
                return "begin test: \(rule)"
            case .endPattern(let pattern, _, _):
                return "end test: \(pattern)"
            case .beginWhile(let rule):
                return "begin test: \(rule)"
            }
        }
    }

    public var position: MatchRulePosition
    public var pattern: Pattern
    
    public init(position: MatchRulePosition,
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
    
    public static func createMatchRule(position: MatchRulePosition,
                                       rule: MatchRule) -> MatchPlan
    {
        return MatchPlan(position: position, pattern: .match(rule))
    }
    
    public static func createBeginRule(position: MatchRulePosition,
                                       rule: BeginEndRule) -> MatchPlan
    {
        return MatchPlan(position: position, pattern: .beginEnd(rule))
    }
    
    public static func createBeginRule(position: MatchRulePosition,
                                       rule: BeginWhileRule) -> MatchPlan
    {
        return MatchPlan(position: position, pattern: .beginWhile(rule))
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

