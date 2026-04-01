//
//  UIPasteboard+Extension.swift
//  
//
//  Created by Семён C. Осипов on 16.08.2024.
//

import Foundation
import UIKit
import CoreServices
import UniformTypeIdentifiers

extension UIPasteboard {
    func setAttributedString(_ attributedString: NSAttributedString) {
        var item = [String: Any]()
        if let rtf = getRtf(from: attributedString) {
            item[rtfType] = rtf
        }
        item[plainTextType] = attributedString.string
        items = [item]
    }
    
    private var rtfType: String {
        if #available(iOS 14.0, *) { return UTType.rtf.identifier }
        return kUTTypeRTF as String
    }
    
    private var plainTextType: String {
        if #available(iOS 14.0, *) { return UTType.plainText.identifier }
        return kUTTypePlainText as String
    }
    
    private func getRtf(from attributedString: NSAttributedString) -> Data? {
        do {
            let rtf = try attributedString.data(from: NSRange(location: 0, length: attributedString.length),
                                                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
            return rtf
        } catch {
            #if DEBUG
            print("Error creating RTF from Attributed String")
            #endif
            return nil
        }
    }
}
