import Foundation
import FineJSON

public final class RuleInjection : CustomStringConvertible {
    public let selector: ScopeSelector
    public let rule: HubRule
    
    public init(selector: ScopeSelector,
                rule: HubRule)
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
        
        let rule = HubRule(sourceLocation: json.sourceLocation,
                           patterns: json.patterns ?? [],
                           repository: nil)
        
        self.init(selector: selector,
                  rule: rule)
    }
    
    public var description: String {
        return "(\(selector))"
    }
}
