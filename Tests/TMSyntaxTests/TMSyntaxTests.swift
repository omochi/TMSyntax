import XCTest
import TMSyntax
import OrderedDictionary

internal extension String {
    // inefficient
    func index(at offset: Int) -> String.Index {
        return self.index(self.startIndex, offsetBy: offset)
    }
}

class TMSyntaxTests: XCTestCase {
    func test1() throws {
        let path = Resources.shared.path("JSON.tmLanguage.json")
        let grammer = try Grammer(contentsOf: path)
//        dump(grammer)
        XCTAssert((grammer.rule.patterns[0] as! IncludeRule).target ===
                (grammer.rule.repository!.dict["value"]))
        
        do {
            let string = "123 456 789"
            let parser = Parser(string: string, grammer: grammer)
            let tokens = try parser.parseLine()
            XCTAssertEqual(tokens, [
                Token(range: string.index(at: 0)..<string.index(at: 3),
                      scopes: [ScopeName("source.json"), ScopeName("constant.numeric.json")]),
                Token(range: string.index(at: 4)..<string.index(at: 7),
                      scopes: [ScopeName("source.json"), ScopeName("constant.numeric.json")]),
                Token(range: string.index(at: 8)..<string.index(at: 11),
                      scopes: [ScopeName("source.json"), ScopeName("constant.numeric.json")]),
                ])
        }
        

    }
    
    func test2() throws {
        let path = Resources.shared.path("JSON.tmLanguage.json")
        let grammer = try Grammer(contentsOf: path)
        
        do {
            let string = "[ 123 ]"
            let parser = Parser(string: string, grammer: grammer)
            let tokens = try parser.parseLine()
        }
    }
    
    func testSplitLines() throws {
        XCTAssertEqual(Parser.splitLines(""), [])
        XCTAssertEqual(Parser.splitLines("a"), ["a"])
        XCTAssertEqual(Parser.splitLines("""
abc

"""),
                       ["abc\n"])
        XCTAssertEqual(Parser.splitLines("""
abc
def
"""),
                       ["abc\n", "def"])
        
        XCTAssertEqual(Parser.splitLines("""
abc

def
"""),
                       ["abc\n", "\n", "def"])

    }
}
