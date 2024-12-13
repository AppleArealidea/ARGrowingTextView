//
//  ARGrowingTextViewDelegate.swift
//  
//
//  Created by Семён C. Осипов on 15.08.2024.
//

import Foundation
import UIKit

@objc public protocol ARGrowingTextViewDelegate: NSObjectProtocol {
    
    @objc optional func growingTextViewShouldBeginEditing(_ growingTextView: ARGrowingTextView) -> Bool
    @objc optional func growingTextViewShouldEndEditing(_ growingTextView: ARGrowingTextView) -> Bool
    
    @objc optional func growingTextViewDidBeginEditing(_ growingTextView: ARGrowingTextView)
    @objc optional func growingTextViewDidEndEditing(_ growingTextView: ARGrowingTextView)
    
    @objc optional func growingTextView(_ growingTextView: ARGrowingTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    @objc optional func growingTextViewDidChange(_ growingTextView: ARGrowingTextView)
    
    @objc optional func growingTextView(_ growingTextView: ARGrowingTextView, willChangeHeight height: CGFloat)
    @objc optional func growingTextView(_ growingTextView: ARGrowingTextView, changeHeightWith diff: CGFloat, animationContext: ARAnimationContext)
    @objc optional func growingTextView(_ growingTextView: ARGrowingTextView, didChangeHeight height: CGFloat)
    
    @objc optional func growingTextViewDidChangeSelection(_ growingTextView: ARGrowingTextView)
    @objc optional func growingTextViewShouldReturn(_ growingTextView: ARGrowingTextView) -> Bool
    
    @objc optional func userDidPaste(images: [UIImage])
}
