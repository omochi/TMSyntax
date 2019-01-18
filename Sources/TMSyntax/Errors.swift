import Foundation
import RichJSONParser

public struct DecodingError : Swift.Error, CustomStringConvertible {
    public var location: SourceLocation
    public var message: String
    
    public init(location: SourceLocation,
                message: String)
    {
        self.location = location
        self.message = message
    }
    
    public var description: String {
        return "decoding error (\(message)) at \(location)"
    }
}
