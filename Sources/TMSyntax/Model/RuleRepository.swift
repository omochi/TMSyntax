import Foundation

public struct RuleRepository : Decodable {
    public init(dictionary: [String: Rule]) {
        self.dictionary = dictionary
    }
    
    private var dictionary: [String: Rule]
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.dictionary = try c.decode([String: Rule].self)
    }
    
    public var entries: [(String, Rule)] {
        return dictionary.map { $0 }
    }
    
    public subscript(name: String) -> Rule? {
        return dictionary[name]
    }
}
