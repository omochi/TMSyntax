import XCTest
import FineJSON
import TMSyntax

class FirstMateTests: XCTestCase {
    struct TestDefinition : Codable {
        public struct Line : Codable {
            public var line: String
            public var tokens: [Token]
        }
        
        public struct Token : Codable, Equatable {
            public var value: String
            public var scopes: [String]
        }
        
        var desc: String
        var grammars: [String]
        var grammarPath: String?
        var grammarScopeName: String?
        var lines: [Line]
    }
    
    func _test1() {
        do {
            let resourceDir = Resources.shared.path("first-mate")
            let testsJSONData = try Data(contentsOf: resourceDir.appendingPathComponent("tests.json"))
            let decoder = FineJSONDecoder()
            let testsJSON = try decoder.decode([TestDefinition].self, from: testsJSONData)
            
            for def in testsJSON {
                try testEntry(dir: resourceDir, def)
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    private func testEntry(dir: URL, _ def: TestDefinition) throws {
        print("test \(def.desc)")
        
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
                let scopes: [String] = token.scopes.map { $0.stringValue }
                let tokenDef = TestDefinition.Token(value: str,
                                                    scopes: scopes)
                return tokenDef
            }
            
            XCTAssertEqual(tokenDefs, lineDef.tokens)
        }
        
    }
}
