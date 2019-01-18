import XCTest
import TMSyntax
import OrderedDictionary

class TMSyntaxTests: XCTestCase {
    func test1() throws {
        let path = Resources.shared.path("JSON.tmLanguage.json")
        let grammer = try Grammer(contentsOf: path)
        
        XCTAssert((grammer.rule.patterns[0] as! IncludeRule).target ===
                (grammer.rule.repository!.dict["value"]))
        
        let string = "123"
        let parser = Parser(string: string, grammer: grammer)
        parser.parseLine()
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
