import Foundation

public final class MatchRule : Rule {
    public var match: String
    public var scopeName: ScopeName
    
    public init(match: String,
                scopeName: ScopeName)
    {
        self.match = match
        self.scopeName = scopeName
    }
    
    public required convenience init(from decoder: Decoder) throws {
        fatalError()
    }
}
