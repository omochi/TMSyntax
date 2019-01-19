import XCTest
import TMSyntax
import OrderedDictionary

class ParserTests: XCTestCase {
    func test1() throws {
        let path = Resources.shared.path("Syntaxes/JSON.tmLanguage.json")
        let grammer = try Grammer(contentsOf: path)

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
    
    func test2() throws {
        let path = Resources.shared.path("Syntaxes/JSON.tmLanguage.json")
        let grammer = try Grammer(contentsOf: path)
        
        let string = "[ 123 ]"
        let parser = Parser(string: string, grammer: grammer)
        let tokens = try parser.parseLine().map { $0.toNaive(string: string) }
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<1, scopes: ["source.json", "meta.structure.array.json"]),
            NaiveToken(range: 1..<2, scopes: ["source.json", "meta.structure.array.json"]),
            NaiveToken(range: 2..<5, scopes: ["source.json", "meta.structure.array.json", "constant.numeric.json"]),
            NaiveToken(range: 5..<6, scopes: ["source.json", "meta.structure.array.json"]),
            NaiveToken(range: 6..<7, scopes: ["source.json", "meta.structure.array.json"])
            ])
    }
    
    func test3() throws {
        let path = Resources.shared.path("Syntaxes/JSON.tmLanguage.json")
        let grammer = try Grammer(contentsOf: path)
        
        let string = "[ [ 123 ] ]"
        let parser = Parser(string: string, grammer: grammer)
        let tokens = try parser.parseLine().map { $0.toNaive(string: string) }
        
        for t in tokens {
            print(t)
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
