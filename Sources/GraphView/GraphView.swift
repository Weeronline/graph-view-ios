#if canImport(UIKit)
import UIKit

public class GraphView: UIView {
    
    var isScrolling = false
    var barWidth: CGFloat = 20
    
    private var temporalNumberOfItems = 10
    private var temportalColorForVerticalLine: UIColor? = UIColor.red
    private let temportalHorizontalLines: [CGFloat] = [0.0, 0.04, 0.2, 0.5, 0.88, 0.9, 1.0]

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
          return
        }
        
        addGraphVerticalLines(size: rect.size)
        addGraphHorizontalLines(size: rect.size)
        
       
        context.saveGState()
    }
    
    // MARK: - Drawing
    
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
        for index in 0..<temportalHorizontalLines.count {
            let linePath = UIBezierPath()
            
            let line = temportalHorizontalLines[index]
            let yAxis = size.height * (1 - line)
            
            linePath.move(to: CGPoint(x: 0, y: yAxis))
            linePath.addLine(to: CGPoint(x: size.width, y: yAxis))
            
            linePath.lineWidth = 1.0
            linePath.stroke()
        }
    }
    
}

#endif
