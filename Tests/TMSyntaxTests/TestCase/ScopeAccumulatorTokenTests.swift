import XCTest
import TMSyntax

class ScopeAccumulatorTokenTests: XCTestCase {
    func testContain() {
        let text = "aabbccbbaa"
        let accum = ScopeAccumulator()
        XCTAssertEqual(accum.buildTokens(), [])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 0)..<text.index(at: 10),
                                  scope: ScopeName("a"))
        )
        XCTAssertEqual(accum.buildTokens().map { $0.toNaive(string: text) }, [
            NaiveToken(range: 0..<10, scopes: ["a"])
            ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 2)..<text.index(at: 8),
                                  scope: ScopeName("b"))
        )
        XCTAssertEqual(accum.buildTokens().map { $0.toNaive(string: text) }, [
            NaiveToken(range: 0..<2, scopes: ["a"]),
            NaiveToken(range: 2..<8, scopes: ["a", "b"]),
            NaiveToken(range: 8..<10, scopes: ["a"])
            ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 4)..<text.index(at: 6),
                                  scope: ScopeName("c"))
        )
        XCTAssertEqual(accum.buildTokens().map { $0.toNaive(string: text) }, [
            NaiveToken(range: 0..<2, scopes: ["a"]),
            NaiveToken(range: 2..<4, scopes: ["a", "b"]),
            NaiveToken(range: 4..<6, scopes: ["a", "b", "c"]),
            NaiveToken(range: 6..<8, scopes: ["a", "b"]),
            NaiveToken(range: 8..<10, scopes: ["a"])
            ])
    }
    
    func testLeftSame() {
        let text = "aaccbbaa"
        let accum = ScopeAccumulator()
        
        accum.items = [
            ScopeAccumulator.Item(range: text.index(at: 0)..<text.index(at: 8),
                                  scope: ScopeName("a")),
            ScopeAccumulator.Item(range: text.index(at: 2)..<text.index(at: 6),
                                  scope: ScopeName("b")),
            ScopeAccumulator.Item(range: text.index(at: 2)..<text.index(at: 4),
                                  scope: ScopeName("c"))
            ]
        XCTAssertEqual(accum.buildTokens().map { $0.toNaive(string: text) }, [
            NaiveToken(range: 0..<2, scopes: ["a"]),
            NaiveToken(range: 2..<4, scopes: ["a", "b", "c"]),
            NaiveToken(range: 4..<6, scopes: ["a", "b"]),
            NaiveToken(range: 6..<8, scopes: ["a"])
            ])
    }
    
    func testRightSame() {
        let text = "aabbccaa"
        let accum = ScopeAccumulator()
        XCTAssertEqual(accum.buildScripts(), [])
        
        accum.items = [
            ScopeAccumulator.Item(range: text.index(at: 0)..<text.index(at: 8),
                                  scope: ScopeName("a")),
            ScopeAccumulator.Item(range: text.index(at: 2)..<text.index(at: 6),
                                  scope: ScopeName("b")),
            ScopeAccumulator.Item(range: text.index(at: 4)..<text.index(at: 6),
                                  scope: ScopeName("c"))
        ]
        XCTAssertEqual(accum.buildTokens().map { $0.toNaive(string: text) }, [
            NaiveToken(range: 0..<2, scopes: ["a"]),
            NaiveToken(range: 2..<4, scopes: ["a", "b"]),
            NaiveToken(range: 4..<6, scopes: ["a", "b", "c"]),
            NaiveToken(range: 6..<8, scopes: ["a"])
            ])
    }
    
    func testNotContain() {
        let text = "aaccccaa"
        let accum = ScopeAccumulator()
        XCTAssertEqual(accum.buildScripts(), [])
        
        accum.items = [
            ScopeAccumulator.Item(range: text.index(at: 0)..<text.index(at: 8),
                                  scope: ScopeName("a")),
            ScopeAccumulator.Item(range: text.index(at: 3)..<text.index(at: 5),
                                  scope: ScopeName("b")),
            ScopeAccumulator.Item(range: text.index(at: 2)..<text.index(at: 6),
                                  scope: ScopeName("c"))
        ]
        XCTAssertEqual(accum.buildTokens().map { $0.toNaive(string: text) }, [
            NaiveToken(range: 0..<2, scopes: ["a"]),
            NaiveToken(range: 2..<3, scopes: ["a", "c"]),
            NaiveToken(range: 3..<5, scopes: ["a", "c", "b"]),
            NaiveToken(range: 5..<6, scopes: ["a", "c"]),
            NaiveToken(range: 6..<8, scopes: ["a"]),
            ])
    }
    
    func testTwoSpike() {
        let text = "abbabba"
        let accum = ScopeAccumulator()
        
        accum.items = [
            ScopeAccumulator.Item(range: text.index(at: 0)..<text.index(at: 7),
                                  scope: ScopeName("a")),
            ScopeAccumulator.Item(range: text.index(at: 1)..<text.index(at: 3),
                                  scope: ScopeName("b")),
            ScopeAccumulator.Item(range: text.index(at: 4)..<text.index(at: 6),
                                  scope: ScopeName("b"))
        ]
        
        XCTAssertEqual(accum.buildTokens().map { $0.toNaive(string: text) }, [
            NaiveToken(range: 0..<1, scopes: ["a"]),
            NaiveToken(range: 1..<3, scopes: ["a", "b"]),
            NaiveToken(range: 3..<4, scopes: ["a"]),
            NaiveToken(range: 4..<6, scopes: ["a", "b"]),
            NaiveToken(range: 6..<7, scopes: ["a"]),
            ])
    }
    
    func testTwoSpikeJoined() {
        let text = "abbcca"
        let accum = ScopeAccumulator()
        accum.items = [
            ScopeAccumulator.Item(range: text.index(at: 0)..<text.index(at: 6),
                                  scope: ScopeName("a")),
            ScopeAccumulator.Item(range: text.index(at: 1)..<text.index(at: 3),
                                  scope: ScopeName("b")),
            ScopeAccumulator.Item(range: text.index(at: 3)..<text.index(at: 5),
                                  scope: ScopeName("c"))
        ]
        XCTAssertEqual(accum.buildTokens().map { $0.toNaive(string: text) }, [
            NaiveToken(range: 0..<1, scopes: ["a"]),
            NaiveToken(range: 1..<3, scopes: ["a", "b"]),
            NaiveToken(range: 3..<5, scopes: ["a", "c"]),
            NaiveToken(range: 5..<6, scopes: ["a"]),
            ])
    }
}

