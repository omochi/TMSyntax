import Foundation

public final class ScopeRule : Rule {
    public var patterns: [Rule] = []
    public override var repository: RuleRepository? {
        return _repository
    }
    private let _repository: RuleRepository?
    
    public init(
        patterns: [Rule],
        repository: RuleRepository?)
    {
        self.patterns = patterns
        self._repository = repository
        super.init()
        
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
