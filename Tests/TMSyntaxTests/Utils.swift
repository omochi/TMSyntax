import Foundation

internal extension String {
    func index(at offset: Int) -> String.Index {
        return self.index(self.startIndex, offsetBy: offset)
    }
}

