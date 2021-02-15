import XCTest
@testable import GraphView
#if canImport(UIKit)

final class GraphViewTests: XCTestCase {
    let graphView = GraphView(frame: CGRect.zero)

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

#endif
