import Foundation
import RichJSONParser

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
