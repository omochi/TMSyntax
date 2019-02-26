import Foundation
import RichJSONParser

public struct CaptureAttributes : Decodable {
    public var dictionary: [String: CaptureAttribute]
    
    public init(dictionary: [String: CaptureAttribute]) {
        self.dictionary = dictionary
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let dict = try c.decode([String: CaptureAttribute].self)
        self.init(dictionary: dict)
    }
}
