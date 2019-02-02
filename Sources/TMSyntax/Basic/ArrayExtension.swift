import Foundation

internal extension Array {
    func compact<T>() -> [T]
        where Element == T?
    {
        return self.compactMap { $0 }
    }
}
