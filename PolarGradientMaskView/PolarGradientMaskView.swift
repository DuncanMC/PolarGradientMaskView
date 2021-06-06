//
//  PolarGradientMaskView.swift
//  PolarGradientMaskView
//
//  Created by Duncan Champney on 6/3/21.
//

import UIKit

protocol PolarGradientMaskViewDelegate: NSObject {
    func animationStepComplete(_ animationStepsRemaining: Int)
}

class PolarGradientMaskView: UIView {

    weak var delegate: PolarGradientMaskViewDelegate?
    public var animateForever = false {
        didSet {
            animationStepsRemaining = animateForever ? Int.max : 4
        }
    }

    var animationStepsRemaining: Int = 0
    public var animating: Bool  = false {
        didSet {
            if animating {
                doRotationAnimation()
            }
        }
    }
    var saveGradientImage = false // Set to true to write the gradient image to the app's documents directory and log the path to the console.
    var oldFrame: CGRect?
    var rotationAngle: CGFloat = 0
    var shapeLayer = CAShapeLayer()
    var gradientLayer = CAGradientLayer()
    var highlightShapeLayer = CAShapeLayer()
    var highlightGradientLayer = CAGradientLayer()
    let lineWidth: CGFloat = 20



    override var bounds: CGRect {
        didSet {
            if bounds != oldFrame {
                shapeLayer.frame = bounds
                gradientLayer.frame = bounds
                highlightShapeLayer.frame = bounds
                highlightGradientLayer.frame = bounds
                let shapeRect = bounds.insetBy(dx: bounds.width / 8, dy: bounds.height / 8)
                shapeLayer.path = buildShapePathIn(shapeRect)
                highlightShapeLayer.path = buildShapePathIn(shapeRect)
                if saveGradientImage {
                    if let image = UIImage.image(from: highlightGradientLayer) {
                        let data = image.pngData()
                        let imageURL = getDocumentsDirectory().appendingPathComponent("highlightConicalGradient.png")
                        print("Saving gradient image to \(imageURL.path)")
                        try? data?.write(to: imageURL)
                    }
                }

            }
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    func buildShapePathIn(_ rect: CGRect) -> CGPath {
        let sides = 6
        let path = UIBezierPath()

        let cornerRadius : CGFloat = 10
        let rotationOffset = CGFloat(.pi / 2.0)

        let theta: CGFloat = CGFloat(2.0 * .pi) / CGFloat(sides) // How much to turn at every corner
        let width = min(rect.size.width, rect.size.height)        // Width of the square

        let center = CGPoint(x: rect.origin.x + width / 2.0, y: rect.origin.y + width / 2.0)

        // Radius of the circle that encircles the polygon
        // Notice that the radius is adjusted for the corners, that way the largest outer
        // dimension of the resulting shape is always exactly the width - linewidth
        let radius = (width - lineWidth + cornerRadius - (cos(theta) * cornerRadius)) / 2.0


        // Start drawing at a point, which by default is at the right hand edge
        // but can be offset
        var angle = CGFloat(rotationOffset)

        let corner = CGPoint(x: center.x + (radius - cornerRadius) * cos(angle), y: center.y + (radius - cornerRadius) * sin(angle))
        path.move(to: CGPoint(x: corner.x + cornerRadius * cos(angle + theta), y: corner.y + cornerRadius * sin(angle + theta)))

        for _ in 0..<sides {
            angle += theta

            let corner = CGPoint(x: center.x + (radius - cornerRadius) * cos(angle), y: center.y + (radius - cornerRadius) * sin(angle))
            let tip = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            let start = CGPoint(x: corner.x + cornerRadius * cos(angle - theta), y: corner.y + cornerRadius * sin(angle - theta))
            let end = CGPoint(x: corner.x + cornerRadius * cos(angle + theta), y: corner.y + cornerRadius * sin(angle + theta))

            path.addLine(to: start)
            path.addQuadCurve(to: end, controlPoint: tip)

        }
        path.close()
        return path.cgPath
    }

    func doInitSetup() {
        shapeLayer.strokeColor = UIColor.yellow.cgColor
        shapeLayer.lineWidth =  lineWidth
        shapeLayer.fillColor = nil
        highlightShapeLayer.strokeColor = UIColor.white.cgColor
        highlightShapeLayer.lineWidth =  lineWidth - 4
        highlightShapeLayer.fillColor = nil

        gradientLayer.type = .conic
        gradientLayer.colors = [UIColor.clear.cgColor,
                                UIColor.clear.cgColor,
                                UIColor.blue.cgColor,
                                UIColor.blue.cgColor]
        let center = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.locations = [0, 0.3, 0.7, 0.9]
        gradientLayer.startPoint = center
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
        self.layer.addSublayer(shapeLayer)
        shapeLayer.mask = gradientLayer
        //---
        highlightGradientLayer.type = .conic
        highlightGradientLayer.colors = [UIColor.clear.cgColor,
                                         UIColor.clear.cgColor,
                                         UIColor(red: 0, green: 0, blue: 1, alpha: 0.5).cgColor,
                                         UIColor(red: 0, green: 0, blue: 1, alpha: 0.9).cgColor,
                                ]
        highlightGradientLayer.locations = [0.00, 0.85, 0.90, 1.00]
        highlightGradientLayer.startPoint = center
        highlightGradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
        self.layer.addSublayer(highlightShapeLayer)
        highlightShapeLayer.mask = highlightGradientLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        doInitSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        doInitSetup()
    }

    public func doRotationAnimation() {
        animationStepsRemaining = animateForever ? Int.max :  4
        shapeLayer.opacity = 1.0
        if !animateForever {
            rotationAngle = 0
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.gradientLayer.transform = CATransform3DMakeRotation(self.rotationAngle, 0, 0, 1)
            self.highlightGradientLayer.transform = CATransform3DMakeRotation(self.rotationAngle, 0, 0, 1)
            CATransaction.commit()
        }
        animateGradientRotationStep()
    }

    #if true
    // This version of the function uses 2 CABasicAnimations
    private func animateGradientRotationStep() {

        // First create animation for the primary hexagon shape layer
        let rotation1 = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation1.fromValue =  rotationAngle
        rotation1.toValue =  rotationAngle + CGFloat.pi / 2
        rotation1.duration = 0.5
        rotation1.delegate = self
        gradientLayer.add(rotation1, forKey: nil)

        // Now create an identical animatoin for the highlight gradient layer
        let rotation2 = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation2.fromValue =  rotationAngle
        rotation2.toValue =  rotationAngle + CGFloat.pi / 2
        rotation2.duration = 0.5
        highlightGradientLayer.add(rotation2, forKey: nil)

        animationStepsRemaining -= 1
        rotationAngle += CGFloat.pi / 2

        // After a tiny delay, set the two layers' transforms to the state at the end of the animation
        // so it doesnt jump back once the animation is complete.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {

            // You have to wrap this step in a CATransaction with setDisableActions(true)
            // So you don't get an implicit animation
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            let newRotation = CATransform3DMakeRotation(self.rotationAngle, 0, 0, 1)
            self.gradientLayer.transform = newRotation
            self.highlightGradientLayer.transform = newRotation
            CATransaction.commit()
        }
    }
    #else
    // This version of the function takes advantage of the fact
    // that a layer's transform property is implicitly animated
    private func animateGradientRotationStep() {
        animationStepsRemaining -= 1
        rotationAngle += CGFloat.pi / 2
        // MARK: - CATransaction begin
        // Use a CATransaction to set the animation duration, timing function, and completion block
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
        CATransaction.setCompletionBlock {
            self.animationDidStop(finished:true)
        }
        let newRotation = CATransform3DMakeRotation(self.rotationAngle, 0, 0, 1)
        self.gradientLayer.transform = newRotation
        self.highlightGradientLayer.transform = newRotation
        CATransaction.commit()
        // MARK: CATransaction end -
    }
    #endif

    func animationDidStop(finished flag: Bool) {
        delegate?.animationStepComplete(animationStepsRemaining)
        if animating && animationStepsRemaining > 0 {
            animateGradientRotationStep()
        } else {
//            shapeLayer.opacity = 0
        }
    }

}

extension PolarGradientMaskView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation,
                          finished flag: Bool) {
        animationDidStop(finished: flag)
    }
}
