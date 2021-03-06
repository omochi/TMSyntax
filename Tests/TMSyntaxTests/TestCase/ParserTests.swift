import XCTest
import TMSyntax

let jsonSyntaxPath = Resources.shared.path("Syntaxes/JSON.tmLanguage.json")
let xmlSyntaxPath = Resources.shared.path("Syntaxes/xml.tmLanguage.json")
let pythonSyntaxPath = Resources.shared.path("Syntaxes/MagicPython.tmLanguage.json")
let phpSyntaxPath = Resources.shared.path("Syntaxes/php.tmLanguage.json")

class ParserTests: XCTestCase {    
    func test1() throws {
        let grammar = try Grammar(contentsOf: jsonSyntaxPath)

        let string = "123 456 789"
        let parser = Parser(string: string, grammar: grammar)
        let tokens = try parser.parseLine().map { $0.toNaive(string: string) }
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<3, scopes: ["source.json", "constant.numeric.json"]),
            NaiveToken(range: 3..<4, scopes: ["source.json"]),
            NaiveToken(range: 4..<7, scopes: ["source.json", "constant.numeric.json"]),
            NaiveToken(range: 7..<8, scopes: ["source.json"]),
            NaiveToken(range: 8..<11, scopes: ["source.json", "constant.numeric.json"]),
            ])
    }
    
    func testBeginCapture0() throws {
        let grammar = try Grammar(contentsOf: jsonSyntaxPath)
        
        let string = "[ 123 ]"
        let parser = Parser(string: string, grammar: grammar)
        let tokens = try parser.parseLine().map { $0.toNaive(string: string) }
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<1, scopes: ["source.json", "meta.structure.array.json", "punctuation.definition.array.begin.json"]),
            NaiveToken(range: 1..<2, scopes: ["source.json", "meta.structure.array.json"]),
            NaiveToken(range: 2..<5, scopes: ["source.json", "meta.structure.array.json", "constant.numeric.json"]),
            NaiveToken(range: 5..<6, scopes: ["source.json", "meta.structure.array.json"]),
            NaiveToken(range: 6..<7, scopes: ["source.json", "meta.structure.array.json", "punctuation.definition.array.end.json"])
            ])
    }
    
    func testNest() throws {
        let grammar = try Grammar(contentsOf: jsonSyntaxPath)
        
        let string = " [ [ 123 ] ] "
        let parser = Parser(string: string, grammar: grammar)
        let tokens = try parser.parseLine().map { $0.toNaive(string: string) }
        
        let lang = "source.json"
        let array = "meta.structure.array.json"
        let arrayBegin = "punctuation.definition.array.begin.json"
        let arrayEnd = "punctuation.definition.array.end.json"
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<1, scopes: [lang]),
            NaiveToken(range: 1..<2, scopes: [lang, array, arrayBegin]),
            NaiveToken(range: 2..<3, scopes: [lang, array]),
            NaiveToken(range: 3..<4, scopes: [lang, array, array, arrayBegin]),
            NaiveToken(range: 4..<5, scopes: [lang, array, array]),
            NaiveToken(range: 5..<8, scopes: [lang, array, array, "constant.numeric.json"]),
            NaiveToken(range: 8..<9, scopes: [lang, array, array]),
            NaiveToken(range: 9..<10, scopes: [lang, array, array, arrayEnd]),
            NaiveToken(range: 10..<11, scopes: [lang, array]),
            NaiveToken(range: 11..<12, scopes: [lang, array, arrayEnd]),
            NaiveToken(range: 12..<13, scopes: [lang]),
            ])
    }
    
    func testMatchRuleCapture0() throws {
        let syntax = """
{
    "name": "test",
    "scopeName": "root",
    "patterns": [
        {
            "match": "aaa",
            "name": "aaa",
            "captures": {
                "0": {
                    "name": "aaa0"
                }
            }
        }
    ]
}
"""
        let grammar = try Grammar(data: syntax.data(using: .utf8)!)
        
        let string = "bbaaabb"
        let parser = Parser(string: string, grammar: grammar)
        let tokens = try parser.parseLine().map { $0.toNaive(string: string) }
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<2, scopes: ["root"]),
            NaiveToken(range: 2..<5, scopes: ["root", "aaa", "aaa0"]),
            NaiveToken(range: 5..<7, scopes: ["root"]),
            ])
    }
    
    func testContentName() throws {
        let syntax = """
{
    "name": "test",
    "scopeName": "root",
    "patterns": [
        {
            "begin": "a",
            "end": "b",
            "name": "outer",
            "contentName": "inner"
        }
    ]
}
"""
        let grammar = try Grammar(data: syntax.data(using: .utf8)!)
        
        let string = "axb"
        let parser = Parser(string: string, grammar: grammar)
        let tokens = try parser.parseLine().map { $0.toNaive(string: string) }
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<1, scopes: ["root", "outer"]),
            NaiveToken(range: 1..<2, scopes: ["root", "outer", "inner"]),
            NaiveToken(range: 2..<3, scopes: ["root", "outer"])
            ])
    }
    
    func testMatchRuleCapture() throws {
        let grammar = try Grammar(contentsOf: xmlSyntaxPath)
        
        let string = "&nbsp;"
        let parser = Parser(string: string, grammar: grammar)
        let tokens = try parser.parseLine().map { $0.toNaive(string: string) }
        
        let lang = "text.xml"
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<1, scopes: [lang, "constant.character.entity.xml", "punctuation.definition.constant.xml"]),
            NaiveToken(range: 1..<5, scopes: [lang, "constant.character.entity.xml"]),
            NaiveToken(range: 5..<6, scopes: [lang, "constant.character.entity.xml", "punctuation.definition.constant.xml"]),
            ])
    }
    
    func testNestMultiline() throws {
        let grammar = try Grammar(contentsOf: jsonSyntaxPath)

        
        let string = """
[
  [
    1,
    2
  ]
]
"""
        let lang = "source.json"
        let array = "meta.structure.array.json"
        let arrayBegin = "punctuation.definition.array.begin.json"
        let arrayEnd = "punctuation.definition.array.end.json"
        let numeric = "constant.numeric.json"
        let comma = "punctuation.separator.array.json"
        
        let parser = Parser(string: string, grammar: grammar)
        var tokens = try parseLine(parser)
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<1, scopes: [lang, array, arrayBegin])
            ])
        
        tokens = try parseLine(parser)
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<2, scopes: [lang, array]),
            NaiveToken(range: 2..<3, scopes: [lang, array, array, arrayBegin])
            ])
        
        tokens = try parseLine(parser)
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<4, scopes: [lang, array, array]),
            NaiveToken(range: 4..<5, scopes: [lang, array, array, numeric]),
            NaiveToken(range: 5..<6, scopes: [lang, array, array, comma]),
            ])
        
        tokens = try parseLine(parser)
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<4, scopes: [lang, array, array]),
            NaiveToken(range: 4..<5, scopes: [lang, array, array, numeric])
            ])
        
        tokens = try parseLine(parser)
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<2, scopes: [lang, array, array]),
            NaiveToken(range: 2..<3, scopes: [lang, array, array, arrayEnd]),
            ])
        
        tokens = try parseLine(parser)
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<1, scopes: [lang, array, arrayEnd]),
            ])
        
        XCTAssertTrue(parser.isAtEnd)
    }
    
    func testEndBackReference() throws {
        let grammar = try Grammar(contentsOf: pythonSyntaxPath)
        
        
        let string = """
u"a'a"
u'a"a'
"""
   
        let lang = "source.python"
        let qstr = "string.quoted.single.python"
        
        let parser = Parser(string: string, grammar: grammar)
        var tokens = try parseLine(parser)
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<1, scopes: [lang, qstr, "storage.type.string.python"]),
            NaiveToken(range: 1..<2, scopes: [lang, qstr, "punctuation.definition.string.begin.python"]),
            NaiveToken(range: 2..<5, scopes: [lang, qstr]),
            NaiveToken(range: 5..<6, scopes: [lang, qstr, "punctuation.definition.string.end.python"]),
            ])
        
        tokens = try parseLine(parser)
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<1, scopes: [lang, qstr, "storage.type.string.python"]),
            NaiveToken(range: 1..<2, scopes: [lang, qstr, "punctuation.definition.string.begin.python"]),
            NaiveToken(range: 2..<5, scopes: [lang, qstr]),
            NaiveToken(range: 5..<6, scopes: [lang, qstr, "punctuation.definition.string.end.python"]),
            ])
    }
    
    func testMatchCaptureNestPattern() throws {
        let grammar = try Grammar(contentsOf: phpSyntaxPath)
        
        let code = """
class BaseClass {
public function __construct(){}
}
"""
        let parser = Parser(string: code, grammar: grammar)
        var tokens = try parseLine(parser)
        
        tokens = try parseLine(parser)
        tokens = Array(tokens[..<5])
        
        XCTAssertEqual(tokens, [
            NaiveToken(range: 0..<6, scopes: [
                "storage.modifier.php",
                "meta.function.php",
                "meta.class.body.php",
                "meta.class.php",
                "source.php",
                ].reversed()),
            NaiveToken(range: 6..<7, scopes: [
                "meta.function.php",
                "meta.class.body.php",
                "meta.class.php",
                "source.php",
                ].reversed()),
            NaiveToken(range: 7..<15, scopes: [
                "storage.type.function.php",
                "meta.function.php",
                "meta.class.body.php",
                "meta.class.php",
                "source.php",
                ].reversed()),
            NaiveToken(range: 15..<16, scopes: [
                "meta.function.php",
                "meta.class.body.php",
                "meta.class.php",
                "source.php",
                ].reversed()),
            NaiveToken(range: 16..<27, scopes: [
                "support.function.magic.php",
                "meta.function.php",
                "meta.class.body.php",
                "meta.class.php",
                "source.php",
                ].reversed()),
            ])
    }
    
    private func parseLine(_ parser: Parser) throws -> [NaiveToken] {
        let line = parser.currentLine!
        return try parser.parseLine().map { $0.toNaive(string: line) }
    }
}
