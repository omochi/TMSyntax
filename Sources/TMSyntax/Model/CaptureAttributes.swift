import Foundation
import OrderedDictionary
import RichJSONParser

public struct CaptureAttributes : Decodable {
    public var dictionary: OrderedDictionary<String, CaptureAttribute>
    
    public init(dictionary: OrderedDictionary<String, CaptureAttribute>) {
        self.dictionary = dictionary
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let dict = try c.decode(OrderedDictionary<String, CaptureAttribute>.self)
        self.init(dictionary: dict)
    }
}
