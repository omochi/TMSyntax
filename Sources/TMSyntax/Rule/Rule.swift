import Foundation
import RichJSONParser

public class Rule : CopyInitializable, Decodable, CustomStringConvertible {
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
}

