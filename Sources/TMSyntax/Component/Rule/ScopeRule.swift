import Foundation
import RichJSONParser

public final class ScopeRule : Rule {
    public let condition: ScopeCondition
    
    public var patterns: [Rule] = []
    public override var repository: RuleRepository? {
        return _repository
    }
    private let _repository: RuleRepository?
    
    public override var scopeName: ScopeName? {
        return _scopeName
    }
    private let _scopeName: ScopeName?
    
    public init(sourceLocation: SourceLocation?,
                condition: ScopeCondition,
                patterns: [Rule],
                repository: RuleRepository?,
                scopeName: ScopeName?)
    {
        self.condition = condition
        self.patterns = patterns
        self._repository = repository
        self._scopeName = scopeName
        super.init(sourceLocation: sourceLocation)
        
        for rule in patterns {
            rule.parent = self
        }
        
        if let repository = repository {            
            for (name, rule) in repository.dict {
                rule.parent = self
                rule.name = name
            }
        }
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError()
    }
}
