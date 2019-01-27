public struct MatchResult {
    public var match: Regex.MatchResult?
    public var position: String.Index
    
    public init(match: Regex.MatchResult?,
                position: String.Index)
    {
        self.match = match
        self.position = position
    }
}
