import Foundation

public enum ScopeCondition {
    case beginEnd(BeginEndCondition)
    case none
}

public final class BeginEndCondition {
    public let begin: RegexPattern
    public let end: RegexPattern
    
    public init(begin: RegexPattern,
                end: RegexPattern)
    {
        self.begin = begin
        self.end = end
    }
}
