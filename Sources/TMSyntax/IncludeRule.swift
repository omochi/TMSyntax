import Foundation

public final class IncludeRule : Rule {
    public let include: IncludeTarget
    
    public init(include: IncludeTarget) {
        self.include = include
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
