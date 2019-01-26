import Foundation
import FineJSON
import enum FineJSON.DecodingError

private let pathKey = CodingUserInfoKey(rawValue: "path")!

public final class Grammer : Decodable, CopyInitializable {
    public let name: String
    public let rule: ScopeRule
    public var scopeName: ScopeName {
        return rule.scopeName!
    }
    
    public enum CodingKeys : String, CodingKey {
        case name
        case scopeName
        case patterns
        case repository
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
        let copy = try decoder.decode(Grammer.self, from: data)
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

        self.rule = ScopeRule(sourceLocation: decoder.sourceLocation,
                              begin: nil,
                              beginCaptures: nil,
                              end: nil,
                              endCaptures: nil,
                              contentName: nil,
                              patterns: patterns,
                              repository: repository,
                              scopeName: scopeName)
        rule.name = "root"
    }
}
