import Foundation
import RichJSONParser

public final class IncludeRule : Rule {
    public let target: IncludeTarget
    
    public init(sourceLocation: SourceLocation?,
                target: IncludeTarget)
    {
        self.target = target
        super.init(sourceLocation: sourceLocation)
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError()
    }
    
    public func resolve(grammer: Grammer) -> Rule? {
        switch target {
        case .repository(let name):
            return self.rule(with: name)
        case .self:
            return grammer.rule
        case .language(let _):
            // TODO
            return nil
        }
    }
}
