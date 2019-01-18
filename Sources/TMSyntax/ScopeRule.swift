import Foundation

public final class ScopeRule : Rule {
    public let patterns: [Rule]
    
    public init(patterns: [Rule]) {
        self.patterns = patterns
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError()
    }
}
