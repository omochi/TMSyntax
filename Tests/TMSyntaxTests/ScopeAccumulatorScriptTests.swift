import XCTest
import TMSyntax

class ScopeAccumulatorScriptTests: XCTestCase {
    func testContain() {
        let text = "aabbccbbaa"
        let accum = ScopeAccumulator()
        XCTAssertEqual(accum.buildScripts(), [])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 0)..<text.index(at: 10),
                                  scope: ScopeName("a"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.pop(0)
        ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 2)..<text.index(at: 8),
                                  scope: ScopeName("b"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.push(1),
            ScopeAccumulator.Script.pop(1),
            ScopeAccumulator.Script.pop(0)
            ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 4)..<text.index(at: 6),
                                  scope: ScopeName("c"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.push(1),
            ScopeAccumulator.Script.push(2),
            ScopeAccumulator.Script.pop(2),
            ScopeAccumulator.Script.pop(1),
            ScopeAccumulator.Script.pop(0)
            ])
    }
    
    func testLeftSame() {
        let text = "aaccbbaa"
        let accum = ScopeAccumulator()
        XCTAssertEqual(accum.buildScripts(), [])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 0)..<text.index(at: 8),
                                  scope: ScopeName("a"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.pop(0)
            ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 2)..<text.index(at: 6),
                                  scope: ScopeName("b"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.push(1),
            ScopeAccumulator.Script.pop(1),
            ScopeAccumulator.Script.pop(0)
            ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 2)..<text.index(at: 4),
                                  scope: ScopeName("c"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.push(1),
            ScopeAccumulator.Script.push(2),
            ScopeAccumulator.Script.pop(2),
            ScopeAccumulator.Script.pop(1),
            ScopeAccumulator.Script.pop(0)
            ])
    }
    
    func testRightSame() {
        let text = "aabbccaa"
        let accum = ScopeAccumulator()
        XCTAssertEqual(accum.buildScripts(), [])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 0)..<text.index(at: 8),
                                  scope: ScopeName("a"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.pop(0)
            ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 2)..<text.index(at: 6),
                                  scope: ScopeName("b"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.push(1),
            ScopeAccumulator.Script.pop(1),
            ScopeAccumulator.Script.pop(0)
            ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 4)..<text.index(at: 6),
                                  scope: ScopeName("c"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.push(1),
            ScopeAccumulator.Script.push(2),
            ScopeAccumulator.Script.pop(2),
            ScopeAccumulator.Script.pop(1),
            ScopeAccumulator.Script.pop(0)
            ])
    }
    
    func testNotContain() {
        let text = "aaccccaa"
        let accum = ScopeAccumulator()
        XCTAssertEqual(accum.buildScripts(), [])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 0)..<text.index(at: 8),
                                  scope: ScopeName("a"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.pop(0)
            ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 3)..<text.index(at: 5),
                                  scope: ScopeName("b"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.push(1),
            ScopeAccumulator.Script.pop(1),
            ScopeAccumulator.Script.pop(0)
            ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 2)..<text.index(at: 6),
                                  scope: ScopeName("c"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.push(2),
            ScopeAccumulator.Script.push(1),
            ScopeAccumulator.Script.pop(1),
            ScopeAccumulator.Script.pop(2),
            ScopeAccumulator.Script.pop(0)
            ])
    }
    
    func testTwoSpike() {
        let text = "abbabba"
        let accum = ScopeAccumulator()
        XCTAssertEqual(accum.buildScripts(), [])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 0)..<text.index(at: 7),
                                  scope: ScopeName("a"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.pop(0)
            ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 1)..<text.index(at: 3),
                                  scope: ScopeName("b"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.push(1),
            ScopeAccumulator.Script.pop(1),
            ScopeAccumulator.Script.pop(0)
            ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 4)..<text.index(at: 6),
                                  scope: ScopeName("b"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.push(1),
            ScopeAccumulator.Script.pop(1),
            ScopeAccumulator.Script.push(2),
            ScopeAccumulator.Script.pop(2),
            ScopeAccumulator.Script.pop(0)
            ])
    }
    
    func testTwoSpikeJoined() {
        let text = "abbcca"
        let accum = ScopeAccumulator()
        XCTAssertEqual(accum.buildScripts(), [])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 0)..<text.index(at: 6),
                                  scope: ScopeName("a"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.pop(0)
            ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 1)..<text.index(at: 3),
                                  scope: ScopeName("b"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.push(1),
            ScopeAccumulator.Script.pop(1),
            ScopeAccumulator.Script.pop(0)
            ])
        
        accum.items.append(
            ScopeAccumulator.Item(range: text.index(at: 3)..<text.index(at: 5),
                                  scope: ScopeName("c"))
        )
        XCTAssertEqual(accum.buildScripts(), [
            ScopeAccumulator.Script.push(0),
            ScopeAccumulator.Script.push(1),
            ScopeAccumulator.Script.pop(1),
            ScopeAccumulator.Script.push(2),
            ScopeAccumulator.Script.pop(2),
            ScopeAccumulator.Script.pop(0)
            ])
    }
}
