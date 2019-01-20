import Foundation
import OrderedDictionary

public struct RuleRepository : Decodable {
    public init(dictionary: OrderedDictionary<String, Rule>) {
        self.dictionary = dictionary
    }
    
    private var dictionary: OrderedDictionary<String, Rule>
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.dictionary = try c.decode(OrderedDictionary<String, Rule>.self)
    }
    
    public var entries: [(String, Rule)] {
        return dictionary.map { $0 }
    }
    
    public subscript(name: String) -> Rule? {
        return dictionary[name]
    }
}
