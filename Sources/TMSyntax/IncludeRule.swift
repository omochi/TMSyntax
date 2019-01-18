import Foundation
import RichJSONParser

public final class IncludeRule : Rule {
    public let include: IncludeTarget
    
    public init(sourceLocation: SourceLocation?,
                include: IncludeTarget)
    {
        self.include = include
        super.init(sourceLocation: sourceLocation)
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError()
    }
    
    public var target: Rule? {
        switch include {
        case .repository(let name):
            return self.rule(with: name)
        case .self:
            return self.parent
        }
    }
}
