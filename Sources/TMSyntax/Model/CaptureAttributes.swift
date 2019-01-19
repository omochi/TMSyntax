import Foundation
import OrderedDictionary

public struct CaptureAttributes : Codable {
    public struct Attribute : Codable {
        public var name: String
    }
    
    public var dictionary: OrderedDictionary<String, Attribute>
    
    public init(dictionary: OrderedDictionary<String, Attribute>) {
        self.dictionary = dictionary
    }
}
