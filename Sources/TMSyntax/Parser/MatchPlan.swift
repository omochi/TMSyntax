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

    public var rulePosition: MatchRulePosition
    public var pattern: Pattern
    
    public init(rulePosition: MatchRulePosition,
                pattern: Pattern)
    {
        self.pattern = pattern
        self.rulePosition = rulePosition
    }
    
    public var description: String {
        var d = pattern.description
        
        switch rulePosition {
        case .none: break
        case .left: d = "L:" + d
        case .right: d = "R:" + d
        }
        
        return d
    }
    
    public static func createMatchRule(rulePosition: MatchRulePosition,
                                       rule: MatchRule) -> MatchPlan
    {
        return MatchPlan(rulePosition: rulePosition, pattern: .match(rule))
    }
    
    public static func createBeginRule(rulePosition: MatchRulePosition,
                                       rule: BeginEndRule) -> MatchPlan
    {
        return MatchPlan(rulePosition: rulePosition, pattern: .beginEnd(rule))
    }
    
    public static func createBeginRule(rulePosition: MatchRulePosition,
                                       rule: BeginWhileRule) -> MatchPlan
    {
        return MatchPlan(rulePosition: rulePosition, pattern: .beginWhile(rule))
    }
    
    public static func createEndPattern(pattern: RegexPattern,
                                        beginMatchResult: Regex.MatchResult?,
                                        beginLineIndex: Int?) -> MatchPlan
    {
        return MatchPlan(rulePosition: .none,
                         pattern: .endPattern(pattern: pattern,
                                              beginMatchResult: beginMatchResult,
                                              beginLineIndex: beginLineIndex))
    }
}

