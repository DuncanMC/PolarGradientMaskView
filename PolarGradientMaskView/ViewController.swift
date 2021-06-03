//
//  ViewController.swift
//  PolarGradientMaskView
//
//  Created by Duncan Champney on 6/3/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var animateSwitch: UISwitch!
    @IBOutlet weak var repeatAnimationSwitch: UISwitch!
    @IBOutlet weak var polarGradientMaskView: PolarGradientMaskView!

    override func viewDidLoad() {
        super.viewDidLoad()
        polarGradientMaskView.delegate = self
    }

    @IBAction func handleAnimateSwitch(_ sender: UISwitch) {
        polarGradientMaskView.animating = sender.isOn
    }
    @IBAction func handleRepeatAnimationSwitch(_ sender: UISwitch) {
        polarGradientMaskView.animateForever = sender.isOn
    }

}

extension ViewController: PolarGradientMaskViewDelegate {
    func animationStepComplete(_ animationStepsRemaining: Int) {
        if animationStepsRemaining == 0 {
            animateSwitch.setOn(false,
                                animated: true)
        }
    }

}

