import Foundation

internal extension Optional {
    mutating func ensure(_ f: () throws -> Wrapped) rethrows -> Wrapped {
        if let x = self {
            return x
        }
        
        let x = try f()
        self = x
        return x
    }
    
    func mapToArray<U>(_ f: (Wrapped) throws -> U) rethrows -> [U] {
        guard let t = self else {
            return []
        }
        let u = try f(t)
        return [u]
    }
}
