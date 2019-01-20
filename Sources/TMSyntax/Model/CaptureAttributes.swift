import Foundation
import OrderedDictionary
import RichJSONParser

public struct CaptureAttributes : Decodable {
    public struct Attribute : Decodable {
        public var sourceLocation: SourceLocation?
        public var name: ScopeName?
        public var patterns: [Rule]
        
        public enum CodingKeys : String, CodingKey {
            case name
            case patterns
        }
        
        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            
            self.sourceLocation = decoder.sourceLocation
            self.name = try c.decodeIfPresent(ScopeName.self, forKey: .name)
            self.patterns = try c.decodeIfPresent([Rule].self, forKey: .patterns) ?? []
        }
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
}
