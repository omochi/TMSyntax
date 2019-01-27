import Foundation

public final class RegexMatchPlan {
    public let pattern: RegexPattern
    public let globalPosition: String.Index?
    
    public init(pattern: RegexPattern,
                globalPosition: String.Index?)
    {
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
