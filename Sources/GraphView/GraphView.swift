#if canImport(UIKit)
import UIKit

@objc
public protocol GraphViewDataSource: AnyObject {
    func numberOfItems(in graphView: GraphView) -> Int
    func graphView(_ graphView: GraphView, pointForItemAt index: Int) -> CGFloat
    @objc optional func graphColor(in graphView: GraphView) -> UIColor
    
    @objc optional func graphView(_ graphView: GraphView, colorForVerticalLineAt index: Int) -> UIColor?
    @objc optional func graphView(_ graphView: GraphView, colorForVerticalBarBackgroundAt index: Int) -> UIColor?
    
    @objc optional func numberOfHorizontalLines(in graphView: GraphView) -> Int
    @objc optional func graphView(_ graphView: GraphView, valueForHorizontalBarAt index: Int) -> CGFloat
    @objc optional func graphView(_ graphView: GraphView, colorForHorizontalBarAt index: Int) -> UIColor

}

@objc
public protocol GraphViewDelegate: AnyObject {
    @objc optional func graphView(_ graphView: GraphView, didSelectBarAt index: Int)
    @objc optional func graphView(_ graphView: GraphView, widthForBarAt index: Int) -> CGFloat
}

public class GraphView: UIView {
    
    @IBOutlet weak var dataSource: GraphViewDataSource?
    @IBOutlet weak var delegate: GraphViewDelegate?

    open private(set) var numberOfItems: Int = 0
    
    var isScrolling = false
    var barWidth: CGFloat = 60
    
    public override var bounds: CGRect {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var items = [CGFloat]()
        
    public override func draw(_ rect: CGRect) {
        resetView()
                
        guard let dataSource = dataSource else {
          return
        }
        
        let context = UIGraphicsGetCurrentContext()
        
        barWidth = delegate?.graphView?(self, widthForBarAt: 0) ?? 20.0
        numberOfItems = dataSource.numberOfItems(in: self)
                
        items = (0..<numberOfItems).map { (index) in
            dataSource.graphView(self, pointForItemAt: index)
        }
        
        let verticalLinesColors = (0...numberOfItems).map { (index) in
            dataSource.graphView?(self, colorForVerticalLineAt: index)
        }
        
        let numberOfHorizontalLines = dataSource.numberOfHorizontalLines?(in: self) ?? 0
        
        let horizontalLines: [(value: CGFloat, color: UIColor)] = (0..<numberOfHorizontalLines).compactMap { (index) in
            if let value = dataSource.graphView?(self, valueForHorizontalBarAt: index),
               let color = dataSource.graphView?(self, colorForHorizontalBarAt: index) {
                return (value: value, color: color)
            }
            return nil
        }
        
        addGraphVerticalLines(size: rect.size, colors: verticalLinesColors)
        addGraphPoints(size: rect.size)
        addGraphHorizontalLines(size: rect.size, horizontalLines: horizontalLines)
       
        context?.saveGState()
    }
    
    public func reloadData() {
        draw(self.bounds)
    }
    
    // MARK: - Drawing
    
    private func resetView() {
        items.removeAll()
        subviews.forEach({ (view) in
            view.removeFromSuperview()
        })
    }
    
    private func addGraphPoints(size: CGSize) {
        let maxValue = 1
        
        let columnXPoint = { (column: Int) -> CGFloat in
            return self.barWidth * CGFloat(column)
        }
        
        let columnYPoint = { (graphPoint: CGFloat) -> CGFloat in
            let yPoint = graphPoint / CGFloat(maxValue) * size.height
            return size.height - yPoint
        }
        
        var points = [CGPoint]()
        for (index,value) in items.enumerated() {
            points.append(CGPoint(x: columnXPoint(index), y: columnYPoint(value)))
        }
        
        points.insert(CGPoint(x:columnXPoint(0), y: columnYPoint(0)), at: 0)
        points.append(CGPoint(x:columnXPoint(points.count), y: columnYPoint(0)))
        
        let bezierPath = UIBezierPath(quadCurve: points)
                
        bezierPath?.fill()
    }
    
    private func addGraphVerticalLines(size: CGSize, colors: [UIColor?]) {
        
        var previousBarView: UIView?
        
        for (index, verticalLineColor) in colors.enumerated() {
            guard let verticalLineColor = verticalLineColor else {
                continue
            }
            
            let shapeLineView = UIView(frame: CGRect.zero )
            shapeLineView.accessibilityIdentifier = "GraphVerticalLine\(index)"
            
            shapeLineView.backgroundColor = verticalLineColor
            
            shapeLineView.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(shapeLineView)
            
            shapeLineView.widthAnchor.constraint(equalToConstant: 1.0).isActive = true
            
            let leadingConstraint: NSLayoutConstraint!
            if let previousBarView = previousBarView {
                leadingConstraint = shapeLineView.leadingAnchor.constraint(equalTo: previousBarView.trailingAnchor, constant: barWidth - 1.0)
            } else {
                leadingConstraint = shapeLineView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
            }
            leadingConstraint.isActive = true
            
            shapeLineView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
            shapeLineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
            
            previousBarView = shapeLineView
        }
    }
    
    private func addGraphHorizontalLines(size: CGSize, horizontalLines: [(value: CGFloat, color: UIColor)]) {
        for (index, horizontalLine) in horizontalLines.enumerated() {
            
            let yAxis = (size.height - 1.0) * horizontalLine.value

            let shapeLineView = UIView(frame: CGRect.zero )
            shapeLineView.accessibilityIdentifier = "GraphHorizontalLine\(index)"
            
            shapeLineView.backgroundColor = horizontalLine.color
            
            shapeLineView.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(shapeLineView)
            
            shapeLineView.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
            shapeLineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -yAxis).isActive = true
            shapeLineView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
            shapeLineView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        }
    }
    
    // Functions
    
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
