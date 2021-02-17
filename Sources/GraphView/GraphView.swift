#if canImport(UIKit)
import UIKit

@objc
protocol GraphViewDataSource: AnyObject {
    func numberOfItems(in graphView: GraphView) -> Int
    func graphView(_ graphView: GraphView, pointForItemAt index: Int) -> CGFloat
    @objc optional func graphColor(in graphView: GraphView) -> UIColor
    
    @objc optional func graphView(_ graphView: GraphView, colorForVerticalLineAt index: Int) -> UIColor?
    @objc optional func graphView(_ graphView: GraphView, colorForVerticalBarBackgroundAt index: Int) -> UIColor?
    
    @objc optional func numberOfHorizontalLines(in graphView: GraphView) -> Int
    @objc optional func graphView(_ graphView: GraphView, horizontalLineForItemAt index: Int) -> Double
    @objc optional func horizontalLineColor(in graphView: GraphView) -> UIColor
}

@objc
protocol GraphViewDelegate: AnyObject {
    @objc optional func graphView(_ graphView: GraphView, didSelectBarAt index: Int)
    @objc optional func graphView(_ graphView: GraphView, widthForBarAt index: Int) -> CGFloat
}

public class GraphView: UIView {
    
    @IBOutlet weak var dataSource: GraphViewDataSource?
    @IBOutlet weak var delegate: GraphViewDelegate?

    var isScrolling = false
    var barWidth: CGFloat = 60
    
    private var items = [CGFloat]()

    private var temporalNumberOfItems = 10
    private var temportalColorForVerticalLine: UIColor? = UIColor.red
    private let temporalHorizontalLines: [CGFloat] = [0.0, 0.04, 0.2, 0.5, 0.88, 0.9, 1.0]
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let dataSource = dataSource else {
          return
        }
        
        items.removeAll()
        
        barWidth = delegate?.graphView?(self, widthForBarAt: 0) ?? 20.0
        
        addGraphPoints(dataSource: dataSource, size: rect.size)
        addGraphVerticalLines(size: rect.size)
        addGraphHorizontalLines(size: rect.size)
       
        context.saveGState()
    }
    
    // MARK: - Drawing
    
    private func addGraphPoints(dataSource: GraphViewDataSource, size: CGSize) {
        let maxValue = 1
        
        let columnXPoint = { (column: Int) -> CGFloat in
            return self.barWidth * CGFloat(column)
        }
        
        let columnYPoint = { (graphPoint: CGFloat) -> CGFloat in
            let yPoint = graphPoint / CGFloat(maxValue) * size.height
            return size.height - yPoint
        }
        
        var points = [CGPoint]()
        for index in 0..<dataSource.numberOfItems(in: self) {
            let value = dataSource.graphView(self, pointForItemAt: index)
            items.append(value)
            points.append(CGPoint(x: columnXPoint(index), y: columnYPoint(value)))
        }
        
        points.insert(CGPoint(x:columnXPoint(0), y: columnYPoint(0)), at: 0)
        points.append(CGPoint(x:columnXPoint(points.count), y: columnYPoint(0)))
        
        
        let bezierPath = UIBezierPath(quadCurve: points)
                
        bezierPath?.fill()
    }
    
    private func addGraphVerticalLines(size: CGSize) {
        for index in 0...temporalNumberOfItems {
            guard let verticalLineColor = temportalColorForVerticalLine else {
                continue
            }

            let linePath = UIBezierPath()
            
            let xAxis = barWidth * CGFloat(index)
            linePath.move(to: CGPoint(x: xAxis, y: 0))
            linePath.addLine(to: CGPoint(x: xAxis, y: size.height))
            
            verticalLineColor.setStroke()
            linePath.lineWidth = 1.0
            linePath.stroke()
        }
    }
    
    private func addGraphHorizontalLines(size: CGSize) {
        for index in 0..<temporalHorizontalLines.count {
            let linePath = UIBezierPath()
            
            let line = temporalHorizontalLines[index]
            let yAxis = size.height * (1 - line)
            
            linePath.move(to: CGPoint(x: 0, y: yAxis))
            linePath.addLine(to: CGPoint(x: size.width, y: yAxis))
            
            linePath.lineWidth = 1.0
            linePath.stroke()
        }
    }
    
    // Functions
    
    open func numberOfItems() -> Int {
        return items.count
    }
    
    open func item(atIndex index: Int) -> CGFloat {
        return items[index]
    }
}

public extension UIBezierPath {
    
    convenience init?(quadCurve points: [CGPoint]) {
        guard points.count > 1 else { return nil }
        
        self.init()

        var p1 = points[0]
        move(to: p1)
        
        if points.count == 2 {
            addLine(to: points[1])
        }
        
        for i in 0..<points.count {
            let mid = midPoint(p1: p1, p2: points[i])
            
            addQuadCurve(to: mid, controlPoint: controlPoint(p1: mid, p2: p1))
            addQuadCurve(to: points[i], controlPoint: controlPoint(p1: mid, p2: points[i]))
            
            p1 = points[i]
        }
    }
    
    private func midPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
    
    private func controlPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        var controlPoint = midPoint(p1: p1, p2: p2)
        let diffY = abs(p2.y - controlPoint.y)
        
        if p1.y < p2.y {
            controlPoint.y += diffY
        } else if p1.y > p2.y {
            controlPoint.y -= diffY
        }
        return controlPoint
    }
}

#endif
