import Foundation
import RichJSONParser

public final class MatchRule : Rule {
    public let match: String
    public let scopeName: ScopeName
    
    private var _matchRegex: Regex?
    public func matchRegex() throws -> Regex {
        return try _matchRegex.ensure {
            try _compileRegex(pattern: match)
        }
    }
    
    public init(sourceLocation: SourceLocation?,
                match: String,
                scopeName: ScopeName)
    {
        self.match = match
        self.scopeName = scopeName
        super.init(sourceLocation: sourceLocation)
    }
    
    public required convenience init(from decoder: Decoder) throws {
        fatalError()
    }
}
