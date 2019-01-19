import XCTest
import TMSyntax
import OrderedDictionary


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
            let tokens = try parser.parseLine().map { $0.toNaive(string: string) }
            XCTAssertEqual(tokens, [
                NaiveToken(range: 0..<3, scopes: ["source.json", "constant.numeric.json"]),
                NaiveToken(range: 3..<4, scopes: ["source.json"]),
                NaiveToken(range: 4..<7, scopes: ["source.json", "constant.numeric.json"]),
                NaiveToken(range: 7..<8, scopes: ["source.json"]),
                NaiveToken(range: 8..<11, scopes: ["source.json", "constant.numeric.json"]),
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
