import Foundation
import OrderedDictionary

public struct RuleRepository : Decodable {
    public var dict: OrderedDictionary<String, Rule>
    
    public init(dict: OrderedDictionary<String, Rule>) {
        self.dict = dict
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.dict = try c.decode(OrderedDictionary<String, Rule>.self)
    }
}
