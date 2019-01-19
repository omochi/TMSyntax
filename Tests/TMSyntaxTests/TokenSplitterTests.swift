import XCTest
import TMSyntax

class TokenSplitterTests: XCTestCase {
    func test1() {
        var string = "123 456 789"
        let splitter = TokenSplitter(rootToken: Token(range: string.startIndex..<string.endIndex,
                                                      scopes: [ScopeName("source.javascript")]))
        XCTAssertEqual(splitter.tokens.map { $0.toNaive(string: string) }, [
            NaiveToken(range: 0..<11, scopes: ["source.javascript"])
            ])
        
        splitter.add(range: string.index(at: 0)..<string.index(at: 3),
                     scopeName: ScopeName("constant.numeric1.json"))
        
        XCTAssertEqual(splitter.tokens.map { $0.toNaive(string: string) }, [
            NaiveToken(range: 0..<3, scopes: ["source.javascript", "constant.numeric1.json"]),
            NaiveToken(range: 3..<11, scopes: ["source.javascript"])
            ])
        
        splitter.add(range: string.index(at: 8)..<string.index(at: 11),
                     scopeName: ScopeName("constant.numeric2.json"))
        
        XCTAssertEqual(splitter.tokens.map { $0.toNaive(string: string) }, [
            NaiveToken(range: 0..<3, scopes: ["source.javascript", "constant.numeric1.json"]),
            NaiveToken(range: 3..<8, scopes: ["source.javascript"]),
            NaiveToken(range: 8..<11, scopes: ["source.javascript", "constant.numeric2.json"])
            ])
        
        splitter.add(range: string.index(at: 4)..<string.index(at: 7),
                     scopeName: ScopeName("constant.numeric3.json"))
        
        XCTAssertEqual(splitter.tokens.map { $0.toNaive(string: string) }, [
            NaiveToken(range: 0..<3, scopes: ["source.javascript", "constant.numeric1.json"]),
            NaiveToken(range: 3..<4, scopes: ["source.javascript"]),
            NaiveToken(range: 4..<7, scopes: ["source.javascript", "constant.numeric3.json"]),
            NaiveToken(range: 7..<8, scopes: ["source.javascript"]),
            NaiveToken(range: 8..<11, scopes: ["source.javascript", "constant.numeric2.json"])
            ])
        
        splitter.add(range: string.index(at: 4)..<string.index(at: 7),
                     scopeName: ScopeName("constant.numeric4.json"))
        
        XCTAssertEqual(splitter.tokens.map { $0.toNaive(string: string) }, [
            NaiveToken(range: 0..<3, scopes: ["source.javascript", "constant.numeric1.json"]),
            NaiveToken(range: 3..<4, scopes: ["source.javascript"]),
            NaiveToken(range: 4..<7, scopes: ["source.javascript", "constant.numeric3.json", "constant.numeric4.json"]),
            NaiveToken(range: 7..<8, scopes: ["source.javascript"]),
            NaiveToken(range: 8..<11, scopes: ["source.javascript", "constant.numeric2.json"])
            ])
    }
}
