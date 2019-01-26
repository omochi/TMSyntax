import Foundation
import RichJSONParser

public final class ScopeRule : Rule {
    public var patterns: [Rule] = []
    public override var repository: RuleRepository? {
        return _repository
    }
    private let _repository: RuleRepository?
    
    public override var scopeName: ScopeName? {
        return _scopeName
    }
    private let _scopeName: ScopeName?

    public let begin: RegexPattern?
    public let beginCaptures: CaptureAttributes?
    public let end: RegexPattern?
    public let endCaptures: CaptureAttributes?
    public let contentName: ScopeName?
    
    public init(sourceLocation: SourceLocation?,
                begin: RegexPattern?,
                beginCaptures: CaptureAttributes?,
                end: RegexPattern?,
                endCaptures: CaptureAttributes?,
                contentName: ScopeName?,
                patterns: [Rule],
                repository: RuleRepository?,
                scopeName: ScopeName?)
    {
        self.begin = begin
        self.beginCaptures = beginCaptures
        
        self.end = end
        self.endCaptures = endCaptures
        
        if let _ = endCaptures {
            precondition(end != nil)
        }
        
        self.contentName = contentName

        self.patterns = patterns
        self._repository = repository
        self._scopeName = scopeName
        super.init(sourceLocation: sourceLocation)
        
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
    
    public required init(from decoder: Decoder) throws {
        fatalError()
    }
}
