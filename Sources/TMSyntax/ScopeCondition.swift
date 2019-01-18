import Foundation

public enum ScopeCondition {
    case beginEnd(BeginEndCondition)
    case none
}

public final class BeginEndCondition {
    public var begin: String
    public var end: String
    
    private var _beginRegex: Regex?
    public func beginRegex(rule: Rule) throws -> Regex {
        return try _beginRegex.ensure {
            try rule._compileRegex(pattern: begin)
        }
    }
    
    public init(begin: String,
                end: String)
    {
        self.begin = begin
        self.end = end
    }
}
