import Foundation

public struct MatchResult {
    public var plan: MatchPlan
    public var match: Regex.Match
    
    public init(plan: MatchPlan,
                match: Regex.Match)
    {
        self.plan = plan
        self.match = match
    }
}
