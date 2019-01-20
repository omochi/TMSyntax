import Foundation
import OrderedDictionary

public final class GrammerRepository {
    public init() {
        self.dictionary = OrderedDictionary()
    }
    
    private var dictionary: OrderedDictionary<ScopeName, Grammer>
    
    public func loadGrammer(path: URL) throws {
        let grammer = try Grammer(contentsOf: path)
        self.dictionary[grammer.scopeName] = grammer
    }
    
    public var entries: [(ScopeName, Grammer)] {
        return dictionary.map { $0 }
    }
    
    public subscript(scopeName: ScopeName) -> Grammer? {
        return dictionary[scopeName]
    }
}
