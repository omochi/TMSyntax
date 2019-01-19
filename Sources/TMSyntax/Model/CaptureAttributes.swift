import Foundation
import OrderedDictionary

public struct CaptureAttributes : Codable {
    public struct Attribute : Codable {
        public var name: ScopeName
    }
    
    public var dictionary: OrderedDictionary<String, Attribute>
    
    public init(dictionary: OrderedDictionary<String, Attribute>) {
        self.dictionary = dictionary
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let dict = try c.decode(OrderedDictionary<String, Attribute>.self)
        self.init(dictionary: dict)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(dictionary)
    }
}
