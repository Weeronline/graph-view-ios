import XCTest
@testable import GraphView
#if canImport(UIKit)

final class GraphViewTests: XCTestCase {
    let graphView = GraphView(frame: CGRect.zero)

    override func setUpWithError() throws {
        UIGraphicsBeginImageContext(CGSize(width: 100.0, height: 100.0))
    }
    
    override func tearDownWithError() throws {
        UIGraphicsEndImageContext()
    }
    
    func testDataSourceAndDelegate() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let graphViewDataSourceTests = GraphViewDataSourceTests()
        let graphViewDelegateTests = GraphViewDelegateTests()
        
        graphView.dataSource = graphViewDataSourceTests
        graphView.delegate = graphViewDelegateTests
        
        graphView.draw(CGRect.zero)

        XCTAssertEqual(10, graphView.numberOfItems())
        XCTAssertEqual(1.0, graphView.item(atIndex: 0))
        XCTAssertEqual(20, graphView.barWidth)
    }

    static var allTests = [
        ("testDataSourceAndDelegate", testDataSourceAndDelegate),
    ]
}

class GraphViewDataSourceTests: GraphViewDataSource {
    func numberOfItems(in graphView: GraphView) -> Int {
        return 10
    }
    
    func graphView(_ graphView: GraphView, pointForItemAt index: Int) -> CGFloat {
        return 1
    }
}

class GraphViewDelegateTests: GraphViewDelegate {
    func graphView(_ graphView: GraphView, widthForBarAt index: Int) -> CGFloat {
        return 20
    }
}

#endif
