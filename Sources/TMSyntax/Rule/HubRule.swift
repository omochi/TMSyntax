import Foundation
import FineJSON

public protocol HubRuleProtocol {
    var patterns: [Rule] { get }
}

extension HubRuleProtocol where Self : Rule {
    internal func setUpChildren() {
        for rule in patterns {
            rule.parent = self
        }
        
        if let repository = repository {
            for (name, rule) in repository.entries {
                rule.parent = self
                rule.name = name
            }
        }
    }
}

public final class HubRule : Rule, HubRuleProtocol {
    public var patterns: [Rule] = []
    private let _repository: RuleRepository?
    
    public init(sourceLocation: SourceLocation?,
                isEnabled: Bool,
                patterns: [Rule],
                repository: RuleRepository?)
    {
        self.patterns = patterns
        self._repository = repository
     
        super.init(sourceLocation: sourceLocation,
                   isEnabled: isEnabled)
        
        setUpChildren()
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError()
    }
    
    public override var switcher: Rule.Switcher {
        return .hub(self)
    }
    
    public override var repository: RuleRepository? {
        return _repository
    }
}
