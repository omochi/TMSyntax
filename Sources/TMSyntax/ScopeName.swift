import Foundation

public struct ScopeName :
    Equatable,
    CustomStringConvertible
{
    public var parts: [String]
    
    public init(_ string: String) {
        self.init(parts: string.components(separatedBy: "."))
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
}

extension ScopeName : HasCodingType {
    public typealias CodingType = String
    
    public init(from codingType: String) {
        self.init(codingType)
    }
    
    public func encodeToCodingType() -> String {
        return stringValue
    }
}
