//
//  String+TypeIdentifiers.swift
//  ARGrowingTextView
//
//  Created by Семён C. Осипов on 15.08.2024.
//

import Foundation
import MobileCoreServices
import UniformTypeIdentifiers

extension String {
    // MARK: Get UTI type string
    static var urlUTIType: String {
        if #available(iOS 14.0, *) {
            return utiType(.url)
        } else {
            return kUTTypeURL as String
        }
    }
    static var rtfUTIType: String {
        if #available(iOS 14.0, *) {
            return utiType(.rtf)
        } else {
            return kUTTypeRTF as String
        }
    }
    static var htmlUTIType: String {
        if #available(iOS 14.0, *) {
            return utiType(.html)
        } else {
            return kUTTypeHTML as String
        }
    }
    static var textUTIType: String {
        if #available(iOS 14.0, *) {
            return utiType(.text)
        } else {
            return kUTTypeText as String
        }
    }
}

@available(iOS 14, macOS 11.0, *)
extension String {
    fileprivate static func utiType(_ utType: UTType) -> String {
        return utType.identifier
    }
}
