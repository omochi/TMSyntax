import Foundation
import OrderedDictionary

public final class GrammarRepository {
    public init() {
        self.dictionary = OrderedDictionary()
        self.injectionScopes = []
    }
    
    private var dictionary: OrderedDictionary<ScopeName, Grammar>

    public var injectionScopes: [ScopeName]
    
    @discardableResult
    public func loadGrammar(path: URL) throws -> Grammar {
        let grammar = try Grammar(contentsOf: path)
        self.dictionary[grammar.scopeName] = grammar
        grammar.repository = self
        return grammar
    }
    
    public var entries: [(ScopeName, Grammar)] {
        return dictionary.map { $0 }
    }
    
    public subscript(scopeName: ScopeName) -> Grammar? {
        return dictionary[scopeName]
    }
    
    public var injections: [RuleInjection] {
        return injectionScopes
            .compactMap { (scope) in
                guard let grammar = self[scope] else {
                    return nil
                }
                return grammar.exportedInjection }
    }
}
