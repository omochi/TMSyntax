import Foundation
import FineJSON
import enum FineJSON.DecodingError
import OrderedDictionary

public final class Grammar {
    public enum Error : LocalizedError, CustomStringConvertible {
        case noName
        
        public var errorDescription: String? { return description }
        
        public var description: String {
            switch self {
            case .noName: return "no name"
            }
        }
    }
    
    public let name: String
    public let rule: ScopeRule
    public var scopeName: ScopeName {
        return rule.scopeName!
    }
    public let injections: [RuleInjection]
    public let exportedInjection: RuleInjection?
    public weak var repository: GrammarRepository?
    
    internal struct JSON : Decodable, JSONAnnotatable {
        public static let keyAnnotations: JSONKeyAnnotations = [
            "sourceLocation": JSONKeyAnnotation(isSourceLocationKey: true)
        ]
        
        public var sourceLocation: SourceLocation?
        public var name: String?
        public var scopeName: ScopeName
        public var patterns: [Rule]?
        public var repository: RuleRepository?
        public var injections: OrderedDictionary<String, RuleInjection.JSON>?
        public var injectionSelector: String?
    }
    
    public convenience init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data, path: url)
    }
    
    public convenience init(data: Data, path: URL? = nil) throws {
        let decoder = FineJSONDecoder()
        decoder.file = path
        let json = try decoder.decode(JSON.self, from: data)
        try self.init(from: json, path: path)
    }
 
    private init(from json: JSON, path: URL?) throws {
        func _name() throws -> String {
            if let name = json.name {
                return name
            }
            if let path = path {
                let fileName = path.lastPathComponent
                if !fileName.isEmpty {
                    let name = fileName.components(separatedBy: ".").first!
                    return name
                }
            }
            throw Error.noName
        }
        
        self.name = try _name()

        var injections: [RuleInjection] = []
        
        if let injectionDict = json.injections {
            for (source, json) in injectionDict {
                let injection = try RuleInjection(selectorSource: source, json: json)
                injections.append(injection)
            }
        }
        
        self.injections = injections
        
        let rule = ScopeRule(sourceLocation: json.sourceLocation,
                             begin: nil,
                             beginCaptures: nil,
                             end: nil,
                             endCaptures: nil,
                             contentName: nil,
                             applyEndPatternLast: false,
                             patterns: json.patterns ?? [],
                             repository: json.repository,
                             scopeName: json.scopeName)
        self.rule = rule
        
        func _exportedInjection() throws -> RuleInjection? {
            guard let source = json.injectionSelector else {
                return nil
            }
            let parser = ScopeSelectorParser(source: source,
                                             pathMatcher: Grammar.pathMatcher)
            let selector = try parser.parse()
            
            return RuleInjection(selector: selector,
                                 rule: rule)
        }
        
        self.exportedInjection = try _exportedInjection()
        
        rule.name = "root"
        rule.setUpRootRule(grammar: self)
        
        for injection in self.injections {
            injection.rule.parent = self.rule
        }
    }
    
    public static func scopeMatcher(pattern: ScopeName, target: ScopeName) -> Bool {
        let patternLen = pattern.parts.count
        guard patternLen <= target.parts.count else {
            return false
        }
        
        return pattern.parts[...] == target.parts[..<patternLen]
    }
    
    public static func pathMatcher(pattern: ScopePath, target: ScopePath) -> Bool {
        var lastIndex = 0
        
        return pattern.items.allSatisfy { (patternItem) in
            for i in lastIndex..<target.items.count {
                let targetItem = target.items[i]
                if scopeMatcher(pattern: patternItem, target: targetItem) {
                    lastIndex = i + 1
                    return true
                }
            }
            return false
        }
    }
}
