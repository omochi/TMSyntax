import Foundation
import RichJSONParser

public final class IncludeRule : Rule {
    public let target: IncludeTarget
    
    public init(sourceLocation: SourceLocation?,
                isEnabled: Bool,
                target: IncludeTarget)
    {
        self.target = target
        super.init(sourceLocation: sourceLocation,
                   isEnabled: isEnabled)
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError()
    }
    
    public override var switcher: Rule.Switcher {
        return .include(self)
    }
    
    public func resolve(base: Grammar) -> Rule? {
        switch target {
        case .repository(let name):
            return self.rule(with: name)
        case .self:
            return self.grammar?.rule
        case .base:
            return base.rule
        case .language(let scope, let name):
            guard let grammar = self.grammarRepository?[scope] else {
                return nil
            }
            if let name = name {
                return grammar.rule.rule(with: name)
            } else {
                return grammar.rule
            }
        }
    }
}
