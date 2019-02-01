import Foundation
import RichJSONParser

public struct RegexCompileError : LocalizedError {
    public var location: SourceLocation?
    public var error: Error
    
    public init(location: SourceLocation?,
                error: Error)
    {
        self.location = location
        self.error = error
    }
    
    public var errorDescription: String? {
        var d: String = "regex compile error (\(error))"
        if let loc = location {
            d += " at \(loc)"
        }
        return d
    }
}
