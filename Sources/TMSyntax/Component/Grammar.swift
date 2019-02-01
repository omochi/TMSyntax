import Foundation
import FineJSON
import enum FineJSON.DecodingError
import OrderedDictionary

private let pathKey = CodingUserInfoKey(rawValue: "path")!

public final class Grammar : Decodable, CopyInitializable {
    public let name: String
    public let rule: ScopeRule
    public var scopeName: ScopeName {
        return rule.scopeName!
    }
    public let injections: [RuleInjection]
    public let exportedInjection: RuleInjection?
    public weak var repository: GrammarRepository?
    
    public enum CodingKeys : String, CodingKey {
        case name
        case scopeName
        case patterns
        case repository
        case injections
        case injectionSelector
    }
    
    public convenience init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data, path: url)
    }
    
    public convenience init(data: Data, path: URL? = nil) throws {
        let decoder = FineJSONDecoder()
        if let path = path {
            decoder.userInfo[pathKey] = path
        }
        let copy = try decoder.decode(Grammar.self, from: data)
        self.init(copy: copy)
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        func _name() throws -> String {
            if let name = try c.decodeIfPresent(String.self, forKey: .name) {
                return name
            }
            if let path = decoder.userInfo[pathKey] as? URL {
                let fileName = path.lastPathComponent
                if !fileName.isEmpty {
                    let name = fileName.components(separatedBy: ".").first!
                    return name
                }
            }
            throw DecodingError.keyNotFound("name",
                                            codingPath: decoder.codingPath,
                                            location: decoder.sourceLocation)
        }
        
        self.name = try _name()
        let scopeName = try c.decode(ScopeName.self, forKey: .scopeName)
        
        let patterns = try c.decodeIfPresent([Rule].self, forKey: .patterns) ?? []
        let repository = try c.decodeIfPresent(RuleRepository.self, forKey: .repository)
        
        var injections: [RuleInjection] = []
        
        if let injectionDict = try c.decodeIfPresent(OrderedDictionary<String, RuleInjection.JSON>.self,
                                                     forKey: .injections)
        {
            for (source, json) in injectionDict {
                let injection = try RuleInjection(selectorSource: source, json: json)
                injections.append(injection)
            }
        }
        
        self.injections = injections
        
        let rule = ScopeRule(sourceLocation: decoder.sourceLocation,
                             begin: nil,
                             beginCaptures: nil,
                             end: nil,
                             endCaptures: nil,
                             contentName: nil,
                             applyEndPatternLast: false,
                             patterns: patterns,
                             repository: repository,
                             scopeName: scopeName)
        self.rule = rule
        
        func _exportedInjection() throws -> RuleInjection? {
            guard let source = try c.decodeIfPresent(String.self, forKey: .injectionSelector) else {
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
    
    public static func pathMatcher(pattern: ScopePath, target: ScopePath) -> Bool {
        return true //TODO
    }
}
