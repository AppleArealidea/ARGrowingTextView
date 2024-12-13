//
//  File.swift
//  
//
//  Created by Семён C. Осипов on 16.08.2024.
//

import Foundation
import UIKit
import CoreServices

extension UIPasteboard {
    func setAttributedString(_ attributedString: NSAttributedString) {
        var item = [String: Any]()
        if let rtf = getRtf(from: attributedString) {
            item[kUTTypeRTF as String] = rtf
        }
        item[kUTTypePlainText as String] = attributedString.string
        items = [item]
    }
    
    private func getRtf(from attributedString: NSAttributedString) -> Data? {
        do {
            let rtf = try attributedString.data(from: NSRange(location: 0, length: attributedString.length),
                                                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
            return rtf
        } catch {
            print("Error creating RTF from Attributed String")
            return nil
        }
    }
}
