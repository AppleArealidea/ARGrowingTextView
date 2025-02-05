//
//  ARGrowingTextView.swift
//  
//
//  Created by Семён C. Осипов on 15.08.2024.
//

import Foundation
import UIKit
import ARMarkdownTextStorage

open class ARGrowingTextView: UIView {
    public weak var delegate: ARGrowingTextViewDelegate?
    
    // MARK: Views
    public private(set) var internalTextView = ARTextViewInternalTextStyle(frame: .zero)
    // Constraints
    private var textViewHeightConstraint: NSLayoutConstraint!
    private var textViewTopConstraint: NSLayoutConstraint!
    private var textViewBottomConstraint: NSLayoutConstraint!
    private var textViewLeadingConstraint: NSLayoutConstraint!
    private var textViewTrailingConstraint: NSLayoutConstraint!
    
    // MARK: Properties
    private var sizeConfig = SizeConfig(minHeight: 0, maxHeight: 0, minNumberOfLines: 1, maxNumberOfLines: 3)
    private var textStorage: NSTextStorage?
    
    public var maxNumberOfLines: Int {
        get { sizeConfig.maxNumberOfLines }
        set {
            if newValue == 0 && maxHeight > 0 { return } // the user specified a maxHeight themselves.
            
            sizeConfig.maxHeight = calculateTextViewHeight(forLinesCount: newValue)
            sizeToFit()
            sizeConfig.maxNumberOfLines = newValue
        }
    }
    public var minNumberOfLines: Int {
        get { sizeConfig.minNumberOfLines }
        set {
            if newValue == 0 && minHeight > 0 { return } // the user specified a minHeight themselves.
            
            sizeConfig.minHeight = calculateTextViewHeight(forLinesCount: newValue)
            sizeToFit()
            sizeConfig.minNumberOfLines = newValue
        }
    }
    public var maxHeight: CGFloat {
        get { sizeConfig.maxHeight }
        set {
            sizeConfig.maxHeight = newValue
            sizeConfig.maxNumberOfLines = 0
        }
    }
    public var minHeight: CGFloat {
        get { sizeConfig.minHeight }
        set {
            sizeConfig.minHeight = newValue
            sizeConfig.minNumberOfLines = 0
        }
    }
    public var animateHeightChange = true
    public var animationDuration: TimeInterval = 0.1
    
    public var text: String? {
        get { internalTextView.text }
        set {
            internalTextView.text = newValue
            // include this line to analyze the height of the textview.
            // fix from Ankit Thakur
            perform(#selector(textViewDidChange(_:)), with: internalTextView)
        }
    }
    public var font: UIFont? {
        get { internalTextView.font }
        set {
            internalTextView.font = newValue
            recalculateMinAndMaxHeights()
        }
    }
    
    public var placeholder: String? {
        get { internalTextView.placeholder }
        set {
            internalTextView.placeholder = newValue
            internalTextView.setNeedsDisplay()
        }
    }
    
    public override var backgroundColor: UIColor? {
        get { internalTextView.backgroundColor }
        set {
            super.backgroundColor = newValue
            internalTextView.backgroundColor = newValue
        }
    }
    
    public var contentInset: UIEdgeInsets = .zero {
        didSet {
            textViewTopConstraint?.constant = contentInset.top
            textViewLeadingConstraint?.constant = contentInset.left
            textViewTrailingConstraint.constant = contentInset.right
            textViewBottomConstraint?.constant = contentInset.bottom
            layoutIfNeeded()
            
            recalculateMinAndMaxHeights()
        }
    }
    
    // MARK: Initialization
    // having initwithcoder allows us to use HPGrowingTextView in a Nib. -- aob, 9/2011
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInitialiser()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInitialiser()
    }
    
    public init() {
        super.init(frame: .zero)
        commonInitialiser()
    }
    
    public init(frame: CGRect, textContainer: NSTextContainer) {
        super.init(frame: frame)
        commonInitialiser(textContainer: textContainer)
    }
    
    private func commonInitialiser() {
        // Create default text container
        let container = NSTextContainer(size: .zero)
        container.widthTracksTextView = true
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(container)
        
        let textStorage = MarkdownTextStorage(font: .systemFont(ofSize: 17))
        textStorage.addLayoutManager(layoutManager)
        
        commonInitialiser(textContainer: container)
    }
    
    private func commonInitialiser(textContainer: NSTextContainer) {
        // Initialization code
        textStorage = textContainer.layoutManager?.textStorage
        
        initInternalTextView(textContainer: textContainer)
        addSubview(internalTextView)
        
        internalTextView.translatesAutoresizingMaskIntoConstraints = false
        
        let height = internalTextView.sizeThatFits(internalTextView.frame.size).height
        
        textViewTopConstraint = internalTextView.topAnchor.constraint(equalTo: topAnchor)
        textViewLeadingConstraint = internalTextView.leadingAnchor.constraint(equalTo: leadingAnchor)
        textViewTrailingConstraint = trailingAnchor.constraint(equalTo: internalTextView.trailingAnchor)
        textViewBottomConstraint = bottomAnchor.constraint(equalTo: internalTextView.bottomAnchor)
        textViewHeightConstraint = internalTextView.heightAnchor.constraint(equalToConstant: height)
        
        NSLayoutConstraint.activate([
            textViewTopConstraint,
            textViewLeadingConstraint,
            textViewTrailingConstraint,
            textViewBottomConstraint,
            textViewHeightConstraint
        ])
        
        sizeConfig.minHeight = height
        
        text = ""
        
        recalculateMinAndMaxHeights()
        
        placeholderColor = .lightGray
        displayPlaceHolder = true
        
        addNotificationsObserver()
    }
    
    deinit {
        removeNotificationObserver()
    }
    
    private func initInternalTextView(textContainer: NSTextContainer?) {
        var rect = self.frame
        rect.origin = CGPoint(x: 0, y: 0)
        
        internalTextView = ARTextViewInternalTextStyle(frame: rect, textContainer: textContainer)
        internalTextView.delegate = self
        internalTextView.customDelegate = self
        internalTextView.isScrollEnabled = false
        internalTextView.contentInset = .zero
        internalTextView.showsHorizontalScrollIndicator = false
        internalTextView.text = "-"
        internalTextView.contentMode = .redraw
        internalTextView.placeholder = "Areal"
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = size
        if text == nil || text!.isEmpty {
            size.height = CGFloat(minHeight)
        }
        return size
    }
    
    // Code from apple developer forum - @Steve Krulewitz, @Mark Marszal, @Eric Silverberg
    private func measureHeight() -> CGFloat {
        return CGFloat(ceilf(Float(internalTextView.sizeThatFits(internalTextView.frame.size).height)))
    }
    
    private func resizeTextView(_ newSizeH: CGFloat) {
        delegate?.growingTextView?(self, willChangeHeight: CGFloat(newSizeH))
        
        guard newSizeH != textViewHeightConstraint.constant else {return}
        textViewHeightConstraint.constant = newSizeH
        layoutIfNeeded()
    }
    
    @objc private func resetScrollPositionForIOS7() {
        guard let selectedRange = internalTextView.selectedTextRange else {return}
        let rect = internalTextView.caretRect(for: selectedRange.end)
        let caretY = max(rect.origin.y - internalTextView.frame.height + rect.height + 8, 0)
        if internalTextView.contentOffset.y < caretY && rect.origin.y != .infinity {
            internalTextView.contentOffset = CGPoint(x: 0, y: caretY)
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        internalTextView.becomeFirstResponder()
    }
    
    // uitextview methods
    // need others? use .internalTextView
    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return internalTextView.becomeFirstResponder()
    }
    
    public override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return internalTextView.resignFirstResponder()
    }
    
    public func scrollRangeToVisible(_ range: NSRange) {
        internalTextView.scrollRangeToVisible(range)
    }
    
    // call to force a height change (e.g. after you change max/min lines)
    public func refreshHeight() {
        let oldHeight = internalTextView.frame.height
        let newSizeH = calculateCurrentTextViewHeight()
        if oldHeight != newSizeH {
            // if our new height is greater than the maxHeight
            // sets not set the height or move things
            // around and enable scrolling
            if newSizeH >= maxHeight {
                if !internalTextView.isScrollEnabled {
                    internalTextView.isScrollEnabled = true
                    internalTextView.flashScrollIndicators()
                    internalTextView.contentSize = internalTextView.sizeThatFits(internalTextView.frame.size)
                }
            } else {
                internalTextView.isScrollEnabled = false
            }
            // [fixed] Pasting too much text into the view failed to fire the height change,
            // thanks to Gwynne <http://blog.darkrainfall.org/>
            if newSizeH <= maxHeight {
                let animationContext = ARAnimationContextImpl()
                if animateHeightChange {
                    delegate?.growingTextView?(self, changeHeightWith: newSizeH - oldHeight, animationContext: animationContext)
                    UIView.animate(withDuration: animationDuration,
                                   delay: 0,
                                   options: [.allowUserInteraction, .beginFromCurrentState],
                                   animations: {
                        self.resizeTextView(newSizeH)
                        animationContext.commitAnimation()
                    },
                                   completion: { _ in
                        self.delegate?.growingTextView?(self, didChangeHeight: newSizeH)
                    })
                } else {
                    delegate?.growingTextView?(self, changeHeightWith: newSizeH - oldHeight, animationContext: animationContext)
                    resizeTextView(newSizeH)
                    animationContext.commitAnimation()
                    delegate?.growingTextView?(self, didChangeHeight: newSizeH)
                }
            }
        }
        
        // Display (or not) the placeholder string
        let wasDisplayingPlaceholder = internalTextView.displayPlaceHolder
        internalTextView.displayPlaceHolder = internalTextView.text.isEmpty
        
        if wasDisplayingPlaceholder != internalTextView.displayPlaceHolder {
            internalTextView.setNeedsDisplay()
        }
        // scroll to caret (needed on iOS7)
        if responds(to: #selector(snapshotView(afterScreenUpdates:))) {
            perform(#selector(resetScrollPositionForIOS7), with: nil, afterDelay: 0.1)
        }
        // Tell the delegate that the text view changed
        delegate?.growingTextViewDidChange?(self)
    }
    
    // Use internalTextView for height calculations, thanks to Gwynne <http://blog.darkrainfall.org/>
    private func calculateTextViewHeight(forLinesCount lines: Int) -> CGFloat {
        let saveText = internalTextView.text
        
        internalTextView.delegate = nil
        internalTextView.isHidden = true
        
        var newText = "|W|"
        let repeatCount = lines > 0 ? lines - 1 : 1
        for _ in 0..<repeatCount {
            newText += "\n|W|"
        }
        
        internalTextView.text = newText
        
        let calculatedHeight = measureHeight()
        
        internalTextView.text = saveText
        internalTextView.isHidden = false
        internalTextView.delegate = self
        
        return calculatedHeight
    }
    
    private func recalculateMinAndMaxHeights() {
        if minNumberOfLines > 0 {
            sizeConfig.minHeight = calculateTextViewHeight(forLinesCount: minNumberOfLines)
        }
        if maxNumberOfLines > 0 {
            sizeConfig.maxHeight = calculateTextViewHeight(forLinesCount: maxNumberOfLines)
        }
        sizeToFit()
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        recalculateMinAndMaxHeights()
        updateHeightConstraint()
    }
    
    private func updateHeightConstraint() {
        let oldHeight = textViewHeightConstraint.constant
        let newHeight = calculateCurrentTextViewHeight()
        if oldHeight != newHeight {
            textViewHeightConstraint.constant = newHeight
            let animationContext = ARAnimationContextImpl()
            delegate?.growingTextView?(self, changeHeightWith: newHeight - oldHeight, animationContext: animationContext)
            animationContext.commitAnimation()
        }
    }
    
    // size of content, so we can set the frame of self
    private func calculateCurrentTextViewHeight() -> CGFloat {
        var newSizeH = measureHeight()
        if newSizeH < minHeight || !internalTextView.hasText {
            newSizeH = minHeight // not smalles than minHeight
        } else if maxHeight > 0 && newSizeH > maxHeight {
            newSizeH = maxHeight // not taller than maxHeight
        }
        return newSizeH
    }
}

extension ARGrowingTextView {
    private struct SizeConfig {
        var minHeight: CGFloat
        var maxHeight: CGFloat
        var minNumberOfLines: Int
        var maxNumberOfLines: Int
    }
}

// MARK: - UITextViewDelegate
extension ARGrowingTextView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        refreshHeight()
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return delegate?.growingTextViewShouldBeginEditing?(self) ?? true
    }
    
    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return delegate?.growingTextViewShouldEndEditing?(self) ?? true
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.growingTextViewDidBeginEditing?(self)
        internalTextView.becomeFirstResponder()
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.growingTextViewDidEndEditing?(self)
        internalTextView.resignFirstResponder()
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // weird 1 pixel bug when clicking backspace when textView is empty
        if !textView.hasText && text == "" {
            return false
        }
        // Added by bretdabaker: sometimes we want to handle this ourselves
        if let delegateResult = delegate?.growingTextView?(self, shouldChangeTextIn: range, replacementText: text) {
            return delegateResult
        }
        if text == "\n" {
            if let delegateResult = delegate?.growingTextViewShouldReturn?(self) {
                if !delegateResult {
                    return true
                } else {
                    textView.resignFirstResponder()
                    return false
                }
            }
        }
        return true
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        delegate?.growingTextViewDidChangeSelection?(self)
    }
}

// MARK: - ARTextViewInternalTextStyleDelegate
extension ARGrowingTextView: ARTextViewInternalTextStyleDelegate {
    public func userDidPasteImages(_ images: [UIImage]) {
        delegate?.userDidPaste?(images: images)
    }
}

// MARK: - Content size category
extension ARGrowingTextView {
    private func addNotificationsObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contentSizeCategoryDidChange(_:)),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
    }
    
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self, name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    @objc private func contentSizeCategoryDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let newContentSizeCategory = userInfo[UIContentSizeCategory.newValueUserInfoKey] as? UIContentSizeCategory else {return}
        updateLayout(for: newContentSizeCategory)
    }
    
    private func updateLayout(for newContentSizeCategory: UIContentSizeCategory) {
        let traitCollection = UITraitCollection(preferredContentSizeCategory: newContentSizeCategory)
        let font = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
        
        if let textStorage = internalTextView.textStorage.layoutManagers.first?.textStorage as? MarkdownTextStorage {
            textStorage.setDefaultFont(font)
        }
        internalTextView.font = font
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayout(for: traitCollection.preferredContentSizeCategory)
    }
}
