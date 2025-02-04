//
//  File.swift
//  ARGrowingTextView
//
//  Created by Семён Осипов on 04.02.2025.
//

import Foundation
import UIKit

/// UITextView properties
public extension ARGrowingTextView {
    
    var displayPlaceHolder: Bool {
        get { internalTextView.displayPlaceHolder }
        set { internalTextView.displayPlaceHolder = newValue }
    }
    var placeholderColor: UIColor? {
        get { internalTextView.placeholderColor }
        set { internalTextView.placeholderColor = newValue }
    }

    var textColor: UIColor? {
        get { internalTextView.textColor }
        set { internalTextView.textColor = newValue }
    }
    var textAlignment: NSTextAlignment {
        get { internalTextView.textAlignment }
        set { internalTextView.textAlignment = newValue }
    }
    var selectedRange: NSRange { // only ranges of length 0 are supported
        get { internalTextView.selectedRange }
        set { internalTextView.selectedRange = newValue }
    }
    var editable: Bool {
        get { internalTextView.isEditable }
        set { internalTextView.isEditable = newValue }
    }
    var dataDetectorTypes: UIDataDetectorTypes {
        get { internalTextView.dataDetectorTypes }
        set { internalTextView.dataDetectorTypes = newValue }
    }
    var returnKeyType: UIReturnKeyType {
        get { internalTextView.returnKeyType }
        set { internalTextView.returnKeyType = newValue }
    }
    var keyboardType: UIKeyboardType {
        get { internalTextView.keyboardType }
        set { internalTextView.keyboardType = newValue }
    }
    var keyboardDismissMode: UIScrollView.KeyboardDismissMode {
        get { internalTextView.keyboardDismissMode }
        set { internalTextView.keyboardDismissMode = newValue }
    }
    var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
        get { internalTextView.contentInsetAdjustmentBehavior }
        set { internalTextView.contentInsetAdjustmentBehavior = newValue }
    }
    @available(iOS, deprecated: 13.0)
    var scrollIndicatorInsets: UIEdgeInsets {
        get { internalTextView.scrollIndicatorInsets }
        set { internalTextView.scrollIndicatorInsets = newValue }
    }
    var verticalScrollIndicatorInsets: UIEdgeInsets {
        get { internalTextView.verticalScrollIndicatorInsets }
        set { internalTextView.verticalScrollIndicatorInsets = newValue}
    }
    var horizontalScrollIndicatorInsets: UIEdgeInsets {
        get { internalTextView.horizontalScrollIndicatorInsets }
        set { internalTextView.horizontalScrollIndicatorInsets = newValue}
    }
    
    var isScrollable: Bool {
        get { internalTextView.isScrollEnabled }
        set { internalTextView.isScrollEnabled = newValue }
    }
    var enablesReturnKeyAutomatically: Bool {
        get { internalTextView.enablesReturnKeyAutomatically }
        set { internalTextView.enablesReturnKeyAutomatically = newValue }
    }
    
    override var isFirstResponder: Bool {
        internalTextView.isFirstResponder
    }
    
    var hasText: Bool {
        internalTextView.hasText
    }
}
