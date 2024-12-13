//
//  ARTextViewInternal.swift
//  
//
//  Created by Семён C. Осипов on 15.08.2024.
//

import UIKit

public class ARTextViewInternal: UITextView {
    var displayPlaceHolder = true
    var placeholderColor: UIColor?
    var placeholder: String? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public override var text: String! {
        get { super.text }
        set {
            let originalValue = isScrollEnabled
            // If one of GrowingTextView's superviews is a scrollView, and self.scrollEnabled == false,
            // setting the text programatically will cause UIKit to search upwards until it finds a scrollView with scrollEnabled==yes
            // then scroll it erratically. Setting scrollEnabled temporarily to YES prevents this.
            isScrollEnabled = true
            super.text = newValue
            isScrollEnabled = originalValue
        }
    }
    
    public override var contentOffset: CGPoint {
        get { super.contentOffset }
        set {
            if isTracking || isDecelerating {
                // initiated by user...
                var insets = contentInset
                insets.bottom = 0
                insets.top = 0
                contentInset = insets
            } else {
                let bottomOffset = contentSize.height - frame.height + contentInset.bottom
                if newValue.y < bottomOffset && isScrollEnabled {
                    var insets = contentInset
                    insets.bottom = 8
                    insets.top = 0
                    contentInset = insets
                }
            }
            // Fix "overscrolling" bug
            var newPoint = newValue
            if newValue.y > contentSize.height - frame.height && !isDecelerating && !isTracking && !isDragging {
                newPoint = CGPoint(x: newValue.x, y: contentSize.height - frame.height)
            }
            super.contentOffset = newPoint
        }
    }
    
    public override var contentInset: UIEdgeInsets {
        get { super.contentInset }
        set {
            var newInsets = newValue
            if newValue.bottom > 8 {
                newInsets.bottom = 0
            }
            newInsets.top = 0
            super.contentInset = newInsets
        }
    }
    
    public override var contentSize: CGSize {
        get { super.contentSize }
        set {
            if contentSize.height > newValue.height { // is this an iOS5 bug? Need testing!
                var insets = contentInset
                insets.bottom = 0
                insets.top = 0
                contentInset = insets
            }
            super.contentSize = newValue
        }
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        let font = font ?? .preferredFont(forTextStyle: .body)
        if displayPlaceHolder,
           let placeholder = placeholder,
           let placeholderColor = placeholderColor {
            if responds(to: #selector(snapshotView(afterScreenUpdates:))) {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = textAlignment
                
                let drawRect = CGRect(x: 5,
                                      y: 8 + contentInset.top,
                                      width: frame.width - contentInset.left,
                                      height: frame.height - contentInset.top)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: placeholderColor,
                    .paragraphStyle: paragraphStyle]
                
                (placeholder as NSString).draw(in: drawRect, withAttributes: attributes)
            } else {
                placeholderColor.set()
                let drawRect = CGRect(x: 8, y: 8, width: frame.width - 16, height: frame.height - 16)
                (placeholder as NSString).draw(in: drawRect, withAttributes: [.font: font])
            }
        }
    }
}
