import Foundation
import RichJSONParser

public class Rule : CopyInitializable, Decodable, CustomStringConvertible {
    internal static let scopeNameBackReferenceRegex: Regex =
        try! Regex(pattern: "b$(bd+)|b${(bd+):b/(bw+)}".replacingOccurrences(of: "b", with: "\\"), options: [])
    
    internal static let regexBackReferenceRegex: Regex =
        try! Regex(pattern: "bb(bd+)".replacingOccurrences(of: "b", with: "\\"), options: [])
    
    internal static let invalidUnicode: Unicode.Scalar = Unicode.Scalar(0xFFFF)!
    internal static let invalidString: String = String(String.UnicodeScalarView([invalidUnicode]))
    
    public enum Switcher {
        case scope(ScopeRule)
        case match(MatchRule)
        case include(IncludeRule)
    }
    
    public var switcher: Switcher {
        switch self {
        case let r as ScopeRule: return .scope(r)
        case let r as MatchRule: return .match(r)
        case let r as IncludeRule: return .include(r)
        default: fatalError("invalid subtype")
        }
    }
    
    public var scopeRule: ScopeRule? { return self as? ScopeRule }
    
    public var name: String?
    public weak var parent: Rule?
    
    public var grammar: Grammar? {
        var ruleOrNone: Rule? = self
        while let rule = ruleOrNone {
            if let grammar = rule._grammar {
                return grammar
            }
            ruleOrNone = rule.parent
        }
        return nil
    }
    private weak var _grammar: Grammar?
    
    public var grammarRepository: GrammarRepository? {
        return grammar?.repository
    }
    
    public var repository: RuleRepository? { return nil }
    public var scopeName: ScopeName? { return nil }
    
    public let sourceLocation: SourceLocation?
    
    public init(sourceLocation: SourceLocation?) {
        self.sourceLocation = sourceLocation
    }
    
    public func setUpRootRule(grammar: Grammar) {
        _grammar = grammar
    }
    
    public var description: String {
        var d = ""
        
        if let name = name {
            d += "[\(name)] "
        } else {
            d += "[--] "
        }
        
        switch switcher {
        case .include(let rule):
            d += "include rule (\(rule.target))"
        case .match(let rule):
            d += "match rule \(rule.pattern)"
        case .scope(let rule):
            if let begin = rule.begin {
                d += "begin end rule \(begin)"
            } else {
                d += "scope rule"
            }
        }
        
        if let loc = sourceLocation {
            d += " at \(loc)"
        }
        
        return d
    }

    public required convenience init(from decoder: Decoder) throws {
        let rule = try Rule.decode(from: decoder)
        self.init(copy: rule)
    }
    
    public func rule(with name: String) -> Rule? {
        var ruleOrNone: Rule? = self
        while let rule = ruleOrNone {
            if let hit = rule.repository?[name] {
                return hit
            }
            ruleOrNone = rule.parent
        }
        return nil
    }
    
    public func resolveScopeName(line: String,
                                 matchResult: Regex.MatchResult)
        throws -> ScopeName?
    {
        guard let name = self.scopeName else {
            return nil
        }
        return try _resolveName(name: name,
                                line: line, matchResult: matchResult)
    }

    internal func _resolveName(name: ScopeName,
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

