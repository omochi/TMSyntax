import Foundation

public struct RegexMatchPlan {
    public var position: MatchRulePosition
    public var pattern: RegexPattern
    public var globalPosition: String.Index?
    
    public init(position: MatchRulePosition,
                pattern: RegexPattern,
                globalPosition: String.Index?)
    {
        self.position = position
        self.pattern = pattern
        self.globalPosition = globalPosition
    }
}
