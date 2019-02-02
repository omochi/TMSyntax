import Foundation

public struct RegexMatchPlan {
    public var rulePosition: MatchRulePosition
    public var pattern: RegexPattern
    public var globalPosition: String.Index?
    
    public init(rulePosition: MatchRulePosition,
                pattern: RegexPattern,
                globalPosition: String.Index?)
    {
        self.rulePosition = rulePosition
        self.pattern = pattern
        self.globalPosition = globalPosition
    }
}
