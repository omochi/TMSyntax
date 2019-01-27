import Foundation
import OrderedDictionary

public final class GrammarRepository {
    public init() {
        self.dictionary = OrderedDictionary()
    }
    
    private var dictionary: OrderedDictionary<ScopeName, Grammar>
    
    public func loadGrammar(path: URL) throws {
        let grammar = try Grammar(contentsOf: path)
        self.dictionary[grammar.scopeName] = grammar
        grammar.repository = self
    }
    
    public var entries: [(ScopeName, Grammar)] {
        return dictionary.map { $0 }
    }
    
    public subscript(scopeName: ScopeName) -> Grammar? {
        return dictionary[scopeName]
    }
}
