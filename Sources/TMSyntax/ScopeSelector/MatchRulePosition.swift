public enum MatchRulePosition : Int, Comparable {
    case left = -1
    case none = 0
    case right = 1
    
    public static func < (a: MatchRulePosition, b: MatchRulePosition) -> Bool {
        return a.rawValue < b.rawValue
    }
}
