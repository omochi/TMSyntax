import Foundation
import TMSyntax

public struct NaiveToken : Equatable {
    public var range: Range<Int>
    public var scopes: [String]
    
    public init(range: Range<Int>,
                scopes: [String])
    {
        self.range = range
        self.scopes = scopes
    }
}

extension Token {
    public func toNaive(string: String) -> NaiveToken {
        let start = string.distance(from: string.startIndex, to: range.lowerBound)
        let end = string.distance(from: string.startIndex, to: range.upperBound)
        let scopes = self.scopes.map { $0.stringValue }
        return NaiveToken(range: start..<end, scopes: scopes)
    }
}
