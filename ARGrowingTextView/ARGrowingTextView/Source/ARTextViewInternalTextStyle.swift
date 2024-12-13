//
//  ARTextViewInternalTextStyle.swift
//  
//
//  Created by Семён C. Осипов on 15.08.2024.
//

import Foundation
import UIKit
import ARMarkdownTextStorage

protocol ARTextViewInternalTextStyleDelegate: AnyObject {
    func userDidPasteImages(_ images: [UIImage])
}

public class ARTextViewInternalTextStyle: ARTextViewInternal {
    weak var customDelegate: ARTextViewInternalTextStyleDelegate?
    
    private var textViewTextFont: UIFont = .preferredFont(forTextStyle: .body)
    private var textViewTextColor: UIColor = .label
    
    public override var font: UIFont? {
        get {
            return super.font
        }
        set {
            super.font = newValue
            textViewTextFont = newValue ?? .systemFont(ofSize: 17.0)
        }
    }
    
    public override var textColor: UIColor? {
        get {
            return super.textColor
        }
        set {
            super.textColor = newValue
            textViewTextColor = newValue ?? .label
        }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        allowsEditingTextAttributes = true
        self.pasteDelegate = self
    }
    
    open override var canBecomeFirstResponder: Bool {
        return true
    }
}

// MARK: - UITextPasteDelegate
extension ARTextViewInternalTextStyle: UITextPasteDelegate {
    public func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
                                                 transform item: UITextPasteItem) {
        
        switch item.itemProvider {
        case let itemProvider where itemProvider.isRTF:
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.rtf,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            if let rtf = UIPasteboard.general.value(forPasteboardType: .rtfUTIType) as? Data,
               let attributedString = try? NSAttributedString(data: rtf,
                                                              options: options,
                                                              documentAttributes: nil) {
                let parsedStr = parsePastedString(attributedString)
                item.setResult(attributedString: parsedStr)
            } else {
                item.setNoResult()
            }
        case let itemProvider where itemProvider.isHTML:
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            if let html = UIPasteboard.general.value(forPasteboardType: .htmlUTIType) as? Data,
               let attributedString = try? NSAttributedString(data: html,
                                                              options: options,
                                                              documentAttributes: nil) {
                let parsedStr = parsePastedString(attributedString)
                item.setResult(attributedString: parsedStr)
            } else {
                item.setNoResult()
            }
        case let itemProvider where itemProvider.isText:
            item.itemProvider.loadObject(ofClass: NSAttributedString.self) { [weak self] (itemProviderReading, error) in
                if let str = itemProviderReading as? NSAttributedString {
                    let parsedStr = self?.parsePastedString(str)
                    item.setResult(attributedString: parsedStr ?? str)
                }
                if let error = error {
                    print(error)
                    item.setNoResult()
                }
            }
        case let itemProvider where itemProvider.isUrl:
            _ = item.itemProvider.loadObject(ofClass: URL.self) { [weak self] (itemProviderReading, error) in
                if let url = itemProviderReading {
                    let str = NSAttributedString(string: url.absoluteString)
                    let parsedStr = self?.parsePastedString(str)
                    item.setResult(attributedString: parsedStr ?? str)
                }
                if let error = error {
                    print(error)
                    item.setNoResult()
                }
            }
        default:
            item.setNoResult()
        }
    }
    
    private func parsePastedString(_ sourceString: NSAttributedString) -> NSAttributedString {
        let sourceString = sourceString.attributedStringByTrimmingCharacterSet(charSet: .whitespacesAndNewlines)
        let parsedStr = NSMutableAttributedString(string: sourceString.string)
        sourceString.enumerateAttributes(in: NSRange(0..<sourceString.length),
                                         options: []) { attributes, range, _ in
            for attribute in attributes {
                switch attribute.key {
                case .font, .strikethroughStyle:
                    parsedStr.addAttribute(attribute.key, value: attribute.value, range: range)
                case .underlineStyle:
                    if !attributes.keys.contains(.link) {
                        parsedStr.addAttribute(attribute.key, value: attribute.value, range: range)
                    }
                default:
                    continue
                }
            }
        }
        
        findAttributedSubstring(sourceString: parsedStr, attribute: .font) { [weak self] (attribute, range) -> (Int) in
            guard let self = self else {return 0}
            if let font = attribute as? UIFont {
                if font.isItalic {
                    return self.markdownText(parsedStr, in: range, with: .italic)
                } else if font.isBold {
                    return self.markdownText(parsedStr, in: range, with: .bold)
                } else {
                    return range.location + range.length
                }
            } else {
                return range.location + range.length
            }
        }
        
        findAttributedSubstring(sourceString: parsedStr, attribute: .underlineStyle) { [weak self] (attribute, range) -> (Int) in
            guard let self = self else {return 0}
            if attribute is NSUnderlineStyle.RawValue {
                return self.markdownText(parsedStr, in: range, with: .underline)
            } else {
                return range.location + range.length
            }
        }
        
        findAttributedSubstring(sourceString: parsedStr, attribute: .strikethroughStyle) { [weak self] (attribute, range) -> (Int) in
            guard let self = self else {return 0}
            if attribute is NSUnderlineStyle.RawValue {
                return self.markdownText(parsedStr, in: range, with: .strikethrough)
            } else {
                return range.location + range.length
            }
        }
        
        let defaultAttributes: [NSAttributedString.Key: Any] = [.font: textViewTextFont,
                                                                .backgroundColor: UIColor.clear,
                                                                .foregroundColor: textViewTextColor,
                                                                .strokeColor: textViewTextColor,
                                                                .strikethroughColor: textViewTextColor,
                                                                .underlineColor: textViewTextColor]
        parsedStr.addAttributes(defaultAttributes, range: NSRange(location: 0, length: parsedStr.length))
        
        return parsedStr
    }
    
    private func findAttributedSubstring(sourceString: NSAttributedString,
                                         attribute: NSAttributedString.Key,
                                         workClosure: (_ attribure: Any, _ range: NSRange) -> (Int)) {
        var location = 0
        while location < sourceString.length {
            sourceString.enumerateAttribute(attribute,
                                         in: NSRange(location..<sourceString.length),
                                         options: []) { attr, range, _ in
                if let attr = attr {
                    location = workClosure(attr, range)
                } else {
                    location = range.location + range.length
                }
            }
        }
    }
    
    private func markdownText(_ text: NSMutableAttributedString, in range: NSRange, with style: MarkdownStyle) -> Int {
        let oldLength = text.length
        text.beginEditing()
        let symbol = NSAttributedString(string: style.symbol())
        text.insert(symbol, at: range.location + range.length)
        text.insert(symbol, at: range.location)
        text.endEditing()
        let newLength = text.length
        let offset = range.location + range.length + newLength - oldLength
        return offset
    }
}

// UIMenu
extension ARTextViewInternalTextStyle {
    enum MarkdownStyle {
        case bold
        case italic
        case strikethrough
        case underline
        
        func symbol() -> String {
            switch self {
            case .bold:
                return RegularExpressionPatterns.boldSymbol
            case .italic:
                return RegularExpressionPatterns.italicSymbol
            case .strikethrough:
                return RegularExpressionPatterns.strikethroughSymbol
            case .underline:
                return RegularExpressionPatterns.underlineSymbol
            }
        }
    }
    
    // MARK: - UIMenu
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        customStyleMenu()
        
        guard EnabledMenuSelectors.contains(action) else {
            print("Disabled selector: \(action)")
            return false
        }
        
        switch action {
        case EnabledMenuSelectors.paste:
            let canPaste = UIPasteboard.general.hasStrings || UIPasteboard.general.hasImages
            guard canPaste else {return false}
        case EnabledMenuSelectors.toggleBoldface,
            EnabledMenuSelectors.toggleItalics,
            EnabledMenuSelectors.toggleUnderline,
            EnabledMenuSelectors.toggleStrikethrough:
            guard selectedRange.length > 0 else {return false}
        default:
            break
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    private func customStyleMenu() {
        let menuController = UIMenuController.shared
        if var menuItems = menuController.menuItems,
           (menuItems.map { $0.action }).elementsEqual([EnabledMenuSelectors.toggleBoldface, EnabledMenuSelectors.toggleItalics, EnabledMenuSelectors.toggleUnderline]) {
            // The font style menu is about to become visible
            // Add a new menu item for strikethrough style
            menuItems.append(UIMenuItem(title: NSLocalizedString("HPTextViewInternalTextStyle.strikethroughActionTitle", comment: ""),
                                        action: EnabledMenuSelectors.toggleStrikethrough))
            menuController.menuItems = menuItems
        }
    }
    
    public override func paste(_ sender: Any?) {
        let pasteboard = UIPasteboard.general
        if pasteboard.hasStrings {
            super.paste(sender)
        }
        if let images = pasteboard.images, !images.isEmpty {
            customDelegate?.userDidPasteImages(images)
        }
    }
    
    public override func copy(_ sender: Any?) {
        let selectedRange = selectedRange
        let selectedText = attributedText.attributedSubstring(from: selectedRange)
        let str = MarkdownParser.attributedString(fromMardown: selectedText.string, font: .preferredFont(forTextStyle: .body), color: .black).attributedString
        UIPasteboard.general.setAttributedString(str)
    }
    
    public override func toggleBoldface(_ sender: Any?) {
        didSelectStyle(.bold)
    }
    
    public override func toggleItalics(_ sender: Any?) {
        didSelectStyle(.italic)
    }
    
    @objc func toggleStrikethrough(_ sender: Any?) {
        didSelectStyle(.strikethrough)
    }
    
    public override func toggleUnderline(_ sender: Any?) {
        didSelectStyle(.underline)
    }
    
    private func didSelectStyle(_ style: MarkdownStyle) {
        guard let selectedRange = self.selectedTextRange, !selectedRange.isEmpty else {return}
        let symbol = style.symbol()
        highlightText(in: selectedRange, withSymbol: symbol)
    }
    
    private func highlightText(in range: UITextRange, withSymbol symbol: String) {
        if let textInRange = self.text(in: range) {
            var formattedText = textInRange
            formattedText.insert(contentsOf: symbol, at: formattedText.startIndex)
            formattedText.insert(contentsOf: symbol, at: formattedText.endIndex)
            self.replace(range, withText: formattedText)
            let endPosition = position(from: range.end, offset: 2*symbol.count)
            let newSelectedRange = textRange(from: range.start, to: endPosition ?? range.end)
            selectedTextRange = newSelectedRange
        }
    }
}

// MARK: - Selectors
extension ARTextViewInternalTextStyle {
    struct EnabledMenuSelectors {
        static let copy = #selector(UIResponderStandardEditActions.copy(_:))
        static let paste = #selector(UIResponderStandardEditActions.paste(_:))
        static let cut = #selector(UIResponderStandardEditActions.cut(_:))
        
        static let select = #selector(UIResponderStandardEditActions.select(_:))
        static let selectAll = #selector(UIResponderStandardEditActions.selectAll(_:))
        
        static let toggleBoldface = #selector(UIResponderStandardEditActions.toggleBoldface(_:))
        static let toggleItalics = #selector(UIResponderStandardEditActions.toggleItalics(_:))
        static let toggleUnderline = #selector(UIResponderStandardEditActions.toggleUnderline(_:))
        static let toggleStrikethrough = #selector(toggleStrikethrough(_:))
        
        
        static func contains(_ selector: Selector) -> Bool {
            switch selector {
            case copy, paste, cut: // Copying
                return true
            case select, selectAll: // Selection
                return true
            case toggleBoldface, toggleItalics, toggleUnderline, toggleStrikethrough:  // Style
                return true
            default:
                return false
            }
        }
    }
}
