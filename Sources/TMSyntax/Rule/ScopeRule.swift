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
    public let applyEndPatternLast: Bool
    
    public init(sourceLocation: SourceLocation?,
                begin: RegexPattern?,
                beginCaptures: CaptureAttributes?,
                end: RegexPattern?,
                endCaptures: CaptureAttributes?,
                contentName: ScopeName?,
                applyEndPatternLast: Bool,
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
        self.applyEndPatternLast = applyEndPatternLast

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
    
    public func resolveContentName(line: String,
                                   matchResult: Regex.MatchResult)
        throws -> ScopeName?
    {
        guard let name = self.contentName else {
            return nil
        }
        return try _resolveName(name: name,
                                line: line,
                                matchResult: matchResult)
    }
    
    
    public func resolveEnd(line: String,
                           matchResult: Regex.MatchResult)
        throws -> RegexPattern
    {
        guard let pattern: RegexPattern = self.end else {
            throw Parser.Error.noEndPattern(self)
        }
        
        var num: Int = 0
        
        func replacer(m: Regex.MatchResult) throws -> String {
            num += 1
            
            guard let captureIndexRange = m[1],
                let captureIndex = Int(pattern.value[captureIndexRange]) else
            {
                throw Parser.Error.invalidRegexPattern(pattern)
            }
            
            guard let range = matchResult[captureIndex] else {
                return Rule.invalidString
            }
            
            return Regex.escape(String(line[range]))
        }
        
        let resolvedPattern = try Rule.regexBackReferenceRegex
            .replace(string: pattern.value, replacer: replacer)
        
        if num == 0 {
            // return same object to make internal cache reusable
            return pattern
        }
        
        return RegexPattern(resolvedPattern, location: pattern.location)
    }
    
    
}
