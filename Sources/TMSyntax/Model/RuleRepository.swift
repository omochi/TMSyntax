import Foundation
import OrderedDictionary

public struct RuleRepository : Decodable {
    public var dictionary: OrderedDictionary<String, Rule>
    
    public init(dictionary: OrderedDictionary<String, Rule>) {
        self.dictionary = dictionary
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.dictionary = try c.decode(OrderedDictionary<String, Rule>.self)
    }
}
