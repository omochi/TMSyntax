import Foundation

internal protocol HasCodingType : Codable {
    associatedtype CodingType : Codable
    
    init(from codingType: CodingType)
    func encodeToCodingType() -> CodingType
}

extension HasCodingType {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let t = try c.decode(CodingType.self)
        self.init(from: t)
    }
}

extension HasCodingType {
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        let t = encodeToCodingType()
        try c.encode(t)
    }
}
