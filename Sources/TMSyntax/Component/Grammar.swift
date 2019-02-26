import Foundation
import FineJSON
import enum FineJSON.DecodingError
import RichJSONParser

public final class Grammar {
    public enum Error : LocalizedError, CustomStringConvertible {
        case noName(SourceLocation?)
        
        public var errorDescription: String? { return description }
        
        public var description: String {
            switch self {
            case .noName(let loc):
                return ["no name", loc.map { "at \($0)" }]
                    .compact().joined(separator: " ")
            }
        }
    }
    
    public let name: String
    public let rule: HubRule
    public let scopeName: ScopeName
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
        public var injections: JSONDictionary<RuleInjection.JSON>?
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
 
    private convenience init(from json: JSON, path: URL?) throws {
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
            throw Error.noName(json.sourceLocation)
        }
        
        let name = try _name()

        var injections: [RuleInjection] = []
        
        if let injectionDict = json.injections {
            for (source, json) in injectionDict {
                let injection = try RuleInjection(selectorSource: source, json: json)
                injections.append(injection)
            }
        }
        
        let scopeName = json.scopeName
        let rule = HubRule(sourceLocation: json.sourceLocation,
                           isEnabled: true,
                           patterns: json.patterns ?? [],
                           repository: json.repository)
        
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
        
        let exportedInjection = try _exportedInjection()
        
        self.init(name: name,
                  rule: rule,
                  scopeName: scopeName,
                  injections: injections,
                  exportedInjection: exportedInjection)
    }
    
    private init(name: String,
                 rule: HubRule,
                 scopeName: ScopeName,
                 injections: [RuleInjection],
                 exportedInjection: RuleInjection?)
    {
        self.name = name
        self.rule = rule
        self.scopeName = scopeName
        self.injections = injections
        self.exportedInjection = exportedInjection
        
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
