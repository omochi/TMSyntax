import XCTest
import FineJSON
import TMSyntax

/*
 grep TEST tests.json | sed -Ee "s/^[^0-9]*([0-9]+)[^0-9]*$/func test\1() throws { try test(id: \1) }/g"
 */
class FirstMateTests: XCTestCase {
    struct TestDefinition : Codable {
        public struct Line : Codable {
            public var line: String
            public var tokens: [Token]
        }
        
        public struct Token : Codable, Equatable, CustomStringConvertible {
            public var value: String
            public var scopes: [String]
            
            public var description: String {
                return "(\(value), \(scopes))"
            }
        }
        
        var desc: String
        var grammars: [String]
        var grammarPath: String?
        var grammarScopeName: String?
        var lines: [Line]
    }
    
    static var resourceDir: URL!
    static var testsJSON: [TestDefinition]!
    
    static override func setUp() {
        do {
            self.resourceDir = Resources.shared.path("first-mate")
            let testsJSONData = try Data(contentsOf: resourceDir.appendingPathComponent("tests.json"))
            let decoder = FineJSONDecoder()
            self.testsJSON = try decoder.decode([TestDefinition].self, from: testsJSONData)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func test3() throws { try test(id: 3) }
    func test4() throws { try test(id: 4) }
    func test5() throws { try test(id: 5) }
    func test6() throws { try test(id: 6) }
    func test7() throws { try test(id: 7) }
    func test8() throws { try test(id: 8) }
    func test9() throws { try test(id: 9) }
    func test10() throws { try test(id: 10) }
    func test11() throws { try test(id: 11) }
    func test12() throws { try test(id: 12) }
    func test13() throws { try test(id: 13) }
    func test14() throws { try test(id: 14) }
    func test15() throws { try test(id: 15) }
    func test16() throws { try test(id: 16) }
    func test17() throws { try test(id: 17) }
    func test18() throws { try test(id: 18) }
    func test19() throws { try test(id: 19) }
    func test20() throws { try test(id: 20) }
    func test21() throws { try test(id: 21) }
    func test22() throws { try test(id: 22) }
    func test23() throws { try test(id: 23) }
    func test24() throws { try test(id: 24) }
    func test25() throws { try test(id: 25) }
    func test26() throws { try test(id: 26) }
    func test27() throws { try test(id: 27) }
    func test28() throws { try test(id: 28) }
    func test29() throws { try test(id: 29) }
    func test30() throws { try test(id: 30) }
    func test31() throws { try test(id: 31) }
    func test32() throws { try test(id: 32) }
    func test33() throws { try test(id: 33) }
    func test34() throws { try test(id: 34) }
    func test35() throws { try test(id: 35) }
    func test36() throws { try test(id: 36) }
    func test37() throws { try test(id: 37) }
    func test38() throws { try test(id: 38) }
    func test39() throws { try test(id: 39) }
    func test42() throws { try test(id: 42) }
    func test44() throws { try test(id: 44) }
    func test45() throws { try test(id: 45) }
    func test46() throws { try test(id: 46) }
    func test47() throws { try test(id: 47) }
    func test48() throws { try test(id: 48) }
    func test49() throws { try test(id: 49) }
    func test50() throws { try test(id: 50) }
    func test51() throws { try test(id: 51) }
    func test53() throws { try test(id: 53) }
    func test54() throws { try test(id: 54) }
    func test55() throws { try test(id: 55) }
    func test56() throws { try test(id: 56) }
    func test57() throws { try test(id: 57) }
    func test58() throws { try test(id: 58) }
    func test61() throws { try test(id: 61) }
    func test62() throws { try test(id: 62) }
    func test63() throws { try test(id: 63) }
    func test64() throws { try test(id: 64) }
    func test65() throws { try test(id: 65) }
    func test66() throws { try test(id: 66) }
    func test67() throws { try test(id: 67) }
    func test68() throws { try test(id: 68) }
    func test71() throws { try test(id: 71) }
    func test72() throws { try test(id: 72) }
    func test73() throws { try test(id: 73) }
    func test74() throws { try test(id: 74) }
    
    private func test(id: Int, file: StaticString = #file, line: UInt = #line) throws {
        let desc = "TEST #\(id)"
        let json = FirstMateTests.testsJSON.first { $0.desc == desc }!
        try testEntry(json, file: file, line: line)
    }
    
    private func testEntry(_ def: TestDefinition, file: StaticString, line: UInt) throws {
        let dir = FirstMateTests.resourceDir!

        let grammerRepository = GrammerRepository()
        for path in def.grammars {
            try grammerRepository.loadGrammer(path: dir.appendingPathComponent(path))
        }
        
        func _grammer() throws -> Grammer {
            if let name = def.grammarScopeName {
                return grammerRepository[ScopeName(name)]!
            }
            if let path = def.grammarPath {
                return try Grammer(contentsOf: dir.appendingPathComponent(path))
            }
            fatalError("unsupported")
        }
        
        let grammer = try _grammer()
        
        let lines = def.lines.map { $0.line }
        
        let parser = Parser(lines: lines, grammer: grammer)
        
        for lineDef in def.lines {
            let lineString = parser.currentLine!
            
            let tokens = try parser.parseLine()
            
            let tokenDefs: [TestDefinition.Token] = tokens.map { (token) in
                let str: String = String(lineString[token.range])
                let scopes: [String] = token.scopePath.map { $0.stringValue }
                let tokenDef = TestDefinition.Token(value: str,
                                                    scopes: scopes)
                return tokenDef
            }
            
            XCTAssertEqual(tokenDefs, lineDef.tokens,
                           file: file, line: line)
        }
        
    }
}
