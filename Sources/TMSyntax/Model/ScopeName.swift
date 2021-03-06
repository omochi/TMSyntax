import Foundation

public struct ScopeName :
    Equatable, Hashable,
    CustomStringConvertible,
    Decodable, Encodable
{
    public var parts: [String]
    
    public init(_ string: String) {
        let parts: [String] = string.components(separatedBy: ".")
        self.init(parts: parts)
    }
    
    public init(parts: [String]) {
        self.parts = parts
    }
    
    public var stringValue: String {
        get {
            return parts.joined(separator: ".")
        }
        set {
            self = ScopeName(newValue)
        }
    }
    
    public var description: String {
        return stringValue
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let str = try c.decode(String.self)
        self.init(str)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(stringValue)
    }
}

extension ScopeName : CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(reflecting: stringValue)
    }
}
