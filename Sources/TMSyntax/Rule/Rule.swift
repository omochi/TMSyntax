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
        case hub(HubRule)
        case beginEnd(BeginEndRule)
        case beginWhile(BeginWhileRule)
        case match(MatchRule)
        case include(IncludeRule)
    }
    
    public var switcher: Switcher {
        fatalError("unimplemented")
    }
    
    public var isEnabled: Bool
    public var name: String?
    public weak var parent: Rule?
    private weak var _grammar: Grammar?
    public let sourceLocation: SourceLocation?

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
    
    public var grammarRepository: GrammarRepository? {
        return grammar?.repository
    }

    public var repository: RuleRepository? { return nil }
    
    public init(sourceLocation: SourceLocation?,
                isEnabled: Bool)
    {
        self.sourceLocation = sourceLocation
        self.isEnabled = isEnabled
    }
    
    public func setUpRootRule(grammar: Grammar) {
        _grammar = grammar
    }
    
    public var description: String {
        var parts: [String?] = []
        
        if let name = name {
            parts.append("[\(name)]")
        } else {
            parts.append("[--]")
        }
        
        switch switcher {
        case .hub(_):
            parts.append("hub rule")
        case .include(let rule):
            parts.append("include rule (\(rule.target))")
        case .match(let rule):
            parts.append("match rule \(rule.pattern)")
        case .beginEnd(let rule):
            parts.append("begin end rule \(rule.begin)")
        case .beginWhile(let rule):
            parts.append("begin while rule \(rule.begin)")
        }
        
        parts.append(sourceLocation.map { "at \($0)" })
        
        return parts.compact().joined(separator: " ")
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
    
}

