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
    public let beginPosition: String.Index?
    public let end: RegexPattern?
    public let endCaptures: CaptureAttributes?
    public let endPosition: String.Index?
    
    public init(sourceLocation: SourceLocation?,
                begin: RegexPattern?,
                beginCaptures: CaptureAttributes?,
                beginPosition: String.Index?,
                end: RegexPattern?,
                endCaptures: CaptureAttributes?,
                endPosition: String.Index?,
                patterns: [Rule],
                repository: RuleRepository?,
                scopeName: ScopeName?)
    {
        self.begin = begin
        self.beginCaptures = beginCaptures
        
        if let _ = beginCaptures {
            precondition(begin != nil)
        }
        
        self.beginPosition = beginPosition
        
        if let _ = beginPosition {
            precondition(begin == nil)
            precondition(beginCaptures == nil)
        }
        
        self.end = end
        self.endCaptures = endCaptures
        
        if let _ = endCaptures {
            precondition(end != nil)
        }
        
        self.endPosition = endPosition
        if let _ = endPosition {
            precondition(end == nil)
            precondition(endCaptures == nil)
        }
        
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
    
    public static func createRangeRule(sourceLocation: SourceLocation?,
                                       range: Range<String.Index>,
                                       patterns: [Rule],
                                       scopeName: ScopeName?) -> ScopeRule {
        return ScopeRule(sourceLocation: sourceLocation,
                         begin: nil,
                         beginCaptures: nil,
                         beginPosition: range.lowerBound,
                         end: nil,
                         endCaptures: nil,
                         endPosition: range.upperBound,
                         patterns: patterns,
                         repository: nil,
                         scopeName: scopeName)
    }
}
