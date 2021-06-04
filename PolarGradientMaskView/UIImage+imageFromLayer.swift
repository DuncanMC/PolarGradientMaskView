//
//  UIImage+imageFromLayer.swift
//  PolarGradientMaskView
//
//  Created by Duncan Champney on 6/4/21.
//

import UIKit


extension UIImage {
  class func image(from layer: CALayer) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(layer.bounds.size,
  layer.isOpaque, UIScreen.main.scale)

    defer { UIGraphicsEndImageContext() }

    // Don't proceed unless we have context
    guard let context = UIGraphicsGetCurrentContext() else {
      return nil
    }

    layer.render(in: context)
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}
