import Foundation
import RichJSONParser

public final class BeginEndRule : Rule, HubRuleProtocol {
    public let begin: RegexPattern
    public let beginCaptures: CaptureAttributes?
    private let end: RegexPattern
    public let endCaptures: CaptureAttributes?
    private let contentName: ScopeName?
    public let applyEndPatternLast: Bool
    public var patterns: [Rule] = []
    private let _repository: RuleRepository?
    private let scopeName: ScopeName?
    
    public init(sourceLocation: SourceLocation?,
                isEnabled: Bool,
                begin: RegexPattern,
                beginCaptures: CaptureAttributes?,
                end: RegexPattern,
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
        
        self.contentName = contentName
        self.applyEndPatternLast = applyEndPatternLast

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
        return .beginEnd(self)
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
    
    public func resolveEnd(line: String,
                           matchResult: Regex.MatchResult)
        throws -> RegexPattern
    {
        return try BeginEndRule.resolveRegex(pattern: end,
                                             line: line,
                                             matchResult: matchResult)
    }
    
    internal static func resolveRegex(pattern: RegexPattern,
                                      line: String,
                                      matchResult: Regex.MatchResult)
        throws -> RegexPattern
    {
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
    
    internal static func resolveNameOptional(name: ScopeName?,
                                             line: String,
                                             matchResult: Regex.MatchResult)
        throws -> ScopeName?
    {
        return try name.map {
            try resolveName(name: $0,
                                 line: line,
                                 matchResult: matchResult)
        }
    }

    internal static func resolveName(name: ScopeName,
                                     line: String,
                                     matchResult: Regex.MatchResult) throws -> ScopeName
    {
        func replacer(part: String, matchResult m: Regex.MatchResult) throws -> String {
            guard let captureIndexRange = m[1] ?? m[2],
                let captureIndex = Int(part[captureIndexRange]),
                let captureRange = matchResult[captureIndex] else
            {
                throw Parser.Error.invalidScopeName(name)
            }
            
            var str = String(line[captureRange])
            
            // I want to remove this.
            // see: https://github.com/Microsoft/vscode-textmate/issues/84
            while str.starts(with: ".") {
                str.removeFirst()
            }
            
            if let modifierRange = m[3] {
                let modifier = part[modifierRange]
                
                switch modifier {
                case "upcase":
                    str = str.uppercased()
                case "downcase":
                    str = str.lowercased()
                default:
                    throw Parser.Error.invalidScopeName(name)
                }
            }
            
            return str
        }
        
        let resolvedParts: [String] = try name.parts.map { (part) in
            try Rule.scopeNameBackReferenceRegex.replace(string: part) { (matchResult) in
                try replacer(part: part, matchResult: matchResult)
            }
        }
        
        return ScopeName(parts: resolvedParts)
    }
    
    
}
