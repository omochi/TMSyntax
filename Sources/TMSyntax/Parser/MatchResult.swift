public struct MatchResult {
    public var plan: MatchPlan
    public var match: Regex.Match?
    public var position: String.Index
    
    public init(plan: MatchPlan,
                match: Regex.Match?,
                position: String.Index)
    {
        self.plan = plan
        self.match = match
        self.position = position
    }
}
