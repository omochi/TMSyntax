public enum ScopeMatchPosition : Int, Comparable {
    case left = -1
    case none = 0
    case right = 1
    
    public static func < (a: ScopeMatchPosition, b: ScopeMatchPosition) -> Bool {
        return a.rawValue < b.rawValue
    }
}
