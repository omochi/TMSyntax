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
    
    public func search(string: String, range: Range<String.Index>) throws -> Regex.MatchResult? {
        let regex = try pattern.compile()
        return regex.search(string: string,
                            range: range,
                            globalPosition: globalPosition)
    }
}
