public struct MatchPlan : CustomStringConvertible {
    public enum Pattern {
        case match(MatchRule)
        case beginEndBegin(BeginEndRule)
        case beginEndEnd(ParserState.BeginEndBegin)
        case beginWhile(BeginWhileRule)
        
        public var description: String {
            switch self {
            case .match(let rule):
                return "test: \(rule)"
            case .beginEndBegin(let rule):
                return "begin test: \(rule)"
            case .beginEndEnd(let state):
                return "end test: \(state.endPattern)"
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
        return MatchPlan(rulePosition: rulePosition, pattern: .beginEndBegin(rule))
    }
    
    public static func createBeginRule(rulePosition: MatchRulePosition,
                                       rule: BeginWhileRule) -> MatchPlan
    {
        return MatchPlan(rulePosition: rulePosition, pattern: .beginWhile(rule))
    }
    
    public static func createEndPattern(state: ParserState.BeginEndBegin) -> MatchPlan
    {
        return MatchPlan(rulePosition: .none,
                         pattern: .beginEndEnd(state))
    }
}

