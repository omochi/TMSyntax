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
    
    public struct JSON : Decodable, JSONAnnotatable {
        public static let keyAnnotations: JSONKeyAnnotations = [
            "sourceLocation": JSONKeyAnnotation(isSourceLocationKey: true)
        ]
        
        public var sourceLocation: SourceLocation?
        public var patterns: [Rule]?
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
                             patterns: json.patterns ?? [],
                             repository: nil,
                             scopeName: nil)
        
        self.init(selector: selector,
                  rule: rule)
    }
    
    public var description: String {
        return "(\(selector))"
    }
}
