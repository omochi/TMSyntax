import Foundation

public struct RegexMatchPlan {
    public var position: ScopeMatchPosition
    public var pattern: RegexPattern
    public var globalPosition: String.Index?
    
    public init(position: ScopeMatchPosition,
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
