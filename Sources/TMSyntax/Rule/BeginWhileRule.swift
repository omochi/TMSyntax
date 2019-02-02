import Foundation
import FineJSON

public final class BeginWhileRule : Rule, HubRuleProtocol {
    public let begin: RegexPattern
    public let beginCaptures: CaptureAttributes?
    private let while_: RegexPattern
    public let whileCaptures: CaptureAttributes?
    private let contentName: ScopeName?
    public var patterns: [Rule] = []
    private let _repository: RuleRepository?
    private let scopeName: ScopeName?
    
    public init(sourceLocation: SourceLocation?,
                isEnabled: Bool,
                begin: RegexPattern,
                beginCaptures: CaptureAttributes?,
                while while_: RegexPattern,
                whileCaptures: CaptureAttributes?,
                contentName: ScopeName?,
                patterns: [Rule],
                repository: RuleRepository?,
                scopeName: ScopeName?)
    {
        self.begin = begin
        self.beginCaptures = beginCaptures
        
        self.while_ = while_
        self.whileCaptures = whileCaptures
        
        self.contentName = contentName
        
        self.patterns = patterns
        self._repository = repository
        self.scopeName = scopeName
        
        super.init(sourceLocation: sourceLocation,
                   isEnabled: isEnabled)
        
        setUpChildren()
    }
    
    public required init(from decoder: Decoder) throws {
        fatalError()
    }
    
    public override var switcher: Rule.Switcher {
        return .beginWhile(self)
    }
    
    public override var repository: RuleRepository? {
        return _repository
    }
    
    public func resolveScopeName(line: String,
                                 matchResult: Regex.MatchResult)
        throws -> ScopeName?
    {
        return try BeginEndRule.resolveNameOptional(name: scopeName,
                                                    line: line,
                                                    matchResult: matchResult)
    }
    
    public func resolveContentName(line: String,
                                   matchResult: Regex.MatchResult)
        throws -> ScopeName?
    {
        return try BeginEndRule.resolveNameOptional(name: contentName,
                                                    line: line,
                                                    matchResult: matchResult)
    }
    
    public func resolveWhile(line: String,
                             matchResult: Regex.MatchResult)
        throws -> RegexPattern
    {
        return try BeginEndRule.resolveRegex(pattern: while_,
                                             line: line,
                                             matchResult: matchResult)
    }
}
