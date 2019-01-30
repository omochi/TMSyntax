import Foundation
import FineJSON

public final class RuleInjection : CustomStringConvertible {
    public let selector: ScopeSelector
    public let rule: ScopeRule
    
    public init(selector: ScopeSelector,
                rule: ScopeRule)
    {
        self.selector = selector
        self.rule = rule
    }
    
    public struct JSON : Decodable {
        public enum CodingKeys : String, CodingKey {
            case patterns
        }
        
        public var sourceLocation: SourceLocation?
        public var patterns: [Rule]
        
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.sourceLocation = decoder.sourceLocation
            self.patterns = try c.decodeIfPresent([Rule].self, forKey: .patterns) ?? []
        }
    }
    
    public convenience init(selectorSource: String,
                            json: JSON) throws
    {
        let parser = ScopeSelectorParser(source: selectorSource, pathMatcher: Grammar.pathMatcher)
        let selector = try parser.parse()
        
        let rule = ScopeRule(sourceLocation: json.sourceLocation,
                             begin: nil,
                             beginCaptures: nil,
                             end: nil,
                             endCaptures: nil,
                             contentName: nil,
                             applyEndPatternLast: false,
                             patterns: json.patterns,
                             repository: nil,
                             scopeName: nil)
        
        self.init(selector: selector,
                  rule: rule)
    }
    
    public var description: String {
        return "(\(selector))"
    }
}
