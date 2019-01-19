import Foundation
import RichJSONParser

public struct DecodingError : Swift.Error, CustomStringConvertible {
    public var location: SourceLocation
    public var message: String
    
    public init(location: SourceLocation,
                _ message: String)
    {
        self.location = location
        self.message = message
    }
    
    public var description: String {
        return "decoding error (\(message)) at \(location)"
    }
}

public struct RegexCompileError : Swift.Error, CustomStringConvertible {
    public var location: SourceLocation?
    public var error: Error
    
    public init(location: SourceLocation?,
                error: Error)
    {
        self.location = location
        self.error = error
    }
    
    public var description: String {
        var d = "regex compile error (\(error))"
        if let loc = location {
            d += " at \(loc)"
        }
        return d
    }
}
