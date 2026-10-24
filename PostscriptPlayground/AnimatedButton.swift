////
//  PostscriptPlayground
//  AnimatedButton
//
//  Created by LegoEsprit on 23.10.26.
//  Copyright (c) 2025 LegoEsprit
//

import Cocoa

class AnimatedButton: NSButton {

    let animation = CAKeyframeAnimation.init(keyPath: "opacity")

    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        start()
    }
    
    
    func start() {
        animation.values = [0.0, 0.5, 1.0, 0.5, 0.0]
        animation.duration = 0.7
        animation.calculationMode = CAAnimationCalculationMode.cubic
        animation.repeatCount = .greatestFiniteMagnitude

        layer?.add(animation, forKey: "opacity")
    }
    
    func stop() {
        layer?.removeAnimation(forKey: "opacity")
    }
    
}
