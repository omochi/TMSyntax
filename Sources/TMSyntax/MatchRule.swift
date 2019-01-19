import Foundation
import RichJSONParser

public final class MatchRule : Rule {
    public let pattern: RegexPattern
    public let scopeName: ScopeName
    
    public init(sourceLocation: SourceLocation?,
                pattern: RegexPattern,
                scopeName: ScopeName)
    {
        self.pattern = pattern
        self.scopeName = scopeName
        super.init(sourceLocation: sourceLocation)
    }
    
    public required convenience init(from decoder: Decoder) throws {
        fatalError()
    }
}
