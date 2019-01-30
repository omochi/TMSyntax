import XCTest
import TMSyntax
import FineJSON

class ScopeSelectorTest: XCTestCase {

    struct TestDefinition : Codable {
        var expression: String
        var input: [String]
        var result: Bool
    }

    // offset line number
    // .
    // .
    // .
    // .
    static let testsJSON = """
[
        { "expression": "foo", "input": ["foo"], "result": true },
        { "expression": "foo", "input": ["bar"], "result": false },
        { "expression": "- foo", "input": ["foo"], "result": false },
        { "expression": "- foo", "input": ["bar"], "result": true },
        { "expression": "- - foo", "input": ["bar"], "result": false },
        { "expression": "bar foo", "input": ["foo"], "result": false },
        { "expression": "bar foo", "input": ["bar"], "result": false },
        { "expression": "bar foo", "input": ["bar", "foo"], "result": true },
        { "expression": "bar - foo", "input": ["bar"], "result": true },
        { "expression": "bar - foo", "input": ["foo", "bar"], "result": false },
        { "expression": "bar - foo", "input": ["foo"], "result": false },
        { "expression": "bar, foo", "input": ["foo"], "result": true },
        { "expression": "bar, foo", "input": ["bar"], "result": true },
        { "expression": "bar, foo", "input": ["bar", "foo"], "result": true },
        { "expression": "bar, -foo", "input": ["bar", "foo"], "result": true },
        { "expression": "bar, -foo", "input": ["yo"], "result": true },
        { "expression": "bar, -foo", "input": ["foo"], "result": false },
        { "expression": "(foo)", "input": ["foo"], "result": true },
        { "expression": "(foo - bar)", "input": ["foo"], "result": true },
        { "expression": "(foo - bar)", "input": ["foo", "bar"], "result": false },
        { "expression": "foo bar - (yo man)", "input": ["foo", "bar"], "result": true },
        { "expression": "foo bar - (yo man)", "input": ["foo", "bar", "yo"], "result": true },
        { "expression": "foo bar - (yo man)", "input": ["foo", "bar", "yo", "man"], "result": false },
        { "expression": "foo bar - (yo | man)", "input": ["foo", "bar", "yo", "man"], "result": false },
        { "expression": "foo bar - (yo | man)", "input": ["foo", "bar", "yo"], "result": false },
        { "expression": "R:text.html - (comment.block, text.html source)", "input": ["text.html", "bar", "source"], "result": false },
        { "expression": "text.html.php - (meta.embedded | meta.tag), L:text.html.php meta.tag, L:source.js.embedded.html", "input": ["text.html.php", "bar", "source.js"], "result": true }
    ]
"""
    
    static var testsDef: [TestDefinition]!
    
    static override func setUp() {
        do {
            let testsJSONData = testsJSON.data(using: .utf8)!
            let decoder = FineJSONDecoder()
            self.testsDef = try decoder.decode([TestDefinition].self, from: testsJSONData)
        } catch {
            XCTFail("\(error)")
        }
    }

    func test00() throws { try test(index: 0) }
    func test01() throws { try test(index: 1) }
    func test02() throws { try test(index: 2) }
    func test03() throws { try test(index: 3) }
    func test04() throws { try test(index: 4) }
    func test05() throws { try test(index: 5) }
    func test06() throws { try test(index: 6) }
    func test07() throws { try test(index: 7) }
    func test08() throws { try test(index: 8) }
    func test09() throws { try test(index: 9) }
    func test10() throws { try test(index: 10) }
    func test11() throws { try test(index: 11) }
    func test12() throws { try test(index: 12) }
    func test13() throws { try test(index: 13) }
    func test14() throws { try test(index: 14) }
    func test15() throws { try test(index: 15) }
    func test16() throws { try test(index: 16) }
    func test17() throws { try test(index: 17) }
    func test18() throws { try test(index: 18) }
    func test19() throws { try test(index: 19) }
    func test20() throws { try test(index: 20) }
    func test21() throws { try test(index: 21) }
    func test22() throws { try test(index: 22) }
    func test23() throws { try test(index: 23) }
    func test24() throws { try test(index: 24) }
    func test25() throws { try test(index: 25) }
    func test26() throws { try test(index: 26) }
    
    private func test(index: Int,
                      file: StaticString = #file, line: UInt = #line) throws
    {
        let defs = ScopeSelectorTest.testsDef!
        let def = defs[index]
        try test(source: def.expression,
                 target: ScopePath(def.input.map { ScopeName($0) }),
                 expected: def.result,
                 file: file, line: line)
    }
    
    static func pathMatcher(pattern: ScopePath, path: ScopePath) -> Bool {
        var lastIndex = 0
        
        return pattern.items.allSatisfy { (part) in
            for i in lastIndex..<path.items.count {
                if part == path.items[i] {
                    lastIndex = i + 1
                    return true
                }
            }
            return false
        }
    }
    
    private func test(source: String, target: ScopePath, expected: Bool,
                      file: StaticString = #file, line: UInt = #line) throws
    {
        let parser = ScopeSelectorParser(source: source,
                                         pathMatcher: ScopeSelectorTest.pathMatcher)
        let selector = try parser.parse()
        let result = selector.match(path: target)
        let actual = result != nil
        XCTAssertEqual(actual, expected, file: file, line: line)
    }

}
