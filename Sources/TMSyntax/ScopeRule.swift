import Foundation
import RichJSONParser

public final class ScopeRule : Rule {
    public let condition: ScopeCondition
    
    public var patterns: [Rule] = []
    public override var repository: RuleRepository? {
        return _repository
    }
    private let _repository: RuleRepository?
    
    public let scopeName: ScopeName?
    
    public init(sourceLocation: SourceLocation?,
                condition: ScopeCondition,
                patterns: [Rule],
                repository: RuleRepository?,
                scopeName: ScopeName?)
    {
        self.condition = condition
        self.patterns = patterns
        self._repository = repository
        self.scopeName = scopeName
        super.init(sourceLocation: sourceLocation)
        
        for rule in patterns {
            rule.parent = self
        }
        
        if let repository = repository {            
            for (_, rule) in repository.dict {
                rule.parent = self
            }
        }
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError()
    }
}
