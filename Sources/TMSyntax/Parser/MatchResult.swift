public struct MatchResult {
    public var match: Regex.Match?
    public var position: String.Index
    
    public init(match: Regex.Match?,
                position: String.Index)
    {
        self.match = match
        self.position = position
    }
}
