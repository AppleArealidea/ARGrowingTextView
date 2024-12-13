//
//  ARAnimationContext.swift
//
//
//  Created by Семён C. Осипов on 16.08.2024.
//

import Foundation

@objc public protocol ARAnimationContext {
    func animate(_ animation: @escaping () -> Void)
}

public class ARAnimationContextImpl: ARAnimationContext {
    private var animationClosure: (() -> Void)?
    
    public init() {}
    
    public func animate(_ animation: @escaping () -> Void) {
        animationClosure = animation
    }
    
    public func commitAnimation() {
        if let animationClosure = animationClosure {
            animationClosure()
        }
    }
}

