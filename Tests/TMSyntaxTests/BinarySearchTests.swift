import XCTest
import TMSyntax

class BinarySearchTests: XCTestCase {
    func test1() {
        XCTAssertEqual([].binarySearch { $0 < 1 }, 0)
        
        XCTAssertEqual([10].binarySearch { $0 < 1 }, 0)
        XCTAssertEqual([10].binarySearch { $0 < 10 }, 0)
        XCTAssertEqual([10].binarySearch { $0 < 12 }, 1)
        
        XCTAssertEqual([10, 20].binarySearch { $0 < 1 }, 0)
        XCTAssertEqual([10, 20].binarySearch { $0 < 10 }, 0)
        XCTAssertEqual([10, 20].binarySearch { $0 < 12 }, 1)
        XCTAssertEqual([10, 20].binarySearch { $0 < 20 }, 1)
        XCTAssertEqual([10, 20].binarySearch { $0 < 22 }, 2)
        
        XCTAssertEqual([10, 10].binarySearch { $0 < 1 }, 0)
        XCTAssertEqual([10, 10].binarySearch { $0 < 10 }, 0)
        XCTAssertEqual([10, 10].binarySearch { $0 < 12 }, 2)
        
        XCTAssertEqual([10, 20, 30].binarySearch { $0 < 1 }, 0)
        XCTAssertEqual([10, 20, 30].binarySearch { $0 < 10 }, 0)
        XCTAssertEqual([10, 20, 30].binarySearch { $0 < 12 }, 1)
        XCTAssertEqual([10, 20, 30].binarySearch { $0 < 20 }, 1)
        XCTAssertEqual([10, 20, 30].binarySearch { $0 < 22 }, 2)
        XCTAssertEqual([10, 20, 30].binarySearch { $0 < 30 }, 2)
        XCTAssertEqual([10, 20, 30].binarySearch { $0 < 32 }, 3)
        
        XCTAssertEqual([10, 10, 10].binarySearch { $0 < 1 }, 0)
        XCTAssertEqual([10, 10, 10].binarySearch { $0 < 10 }, 0)
        XCTAssertEqual([10, 10, 10].binarySearch { $0 < 12 }, 3)
        
        XCTAssertEqual([10, 10, 20].binarySearch { $0 < 1 }, 0)
        XCTAssertEqual([10, 10, 20].binarySearch { $0 < 10 }, 0)
        XCTAssertEqual([10, 10, 20].binarySearch { $0 < 12 }, 2)
        XCTAssertEqual([10, 10, 20].binarySearch { $0 < 20 }, 2)
        XCTAssertEqual([10, 10, 20].binarySearch { $0 < 22 }, 3)
        
        XCTAssertEqual([10, 20, 20].binarySearch { $0 < 1 }, 0)
        XCTAssertEqual([10, 20, 20].binarySearch { $0 < 10 }, 0)
        XCTAssertEqual([10, 20, 20].binarySearch { $0 < 12 }, 1)
        XCTAssertEqual([10, 20, 20].binarySearch { $0 < 20 }, 1)
        XCTAssertEqual([10, 20, 20].binarySearch { $0 < 22 }, 3)
    }
}
