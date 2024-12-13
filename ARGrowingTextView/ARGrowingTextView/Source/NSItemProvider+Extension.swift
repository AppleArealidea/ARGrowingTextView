//
//  NSItemProvider+Extension.swift
//  ARGrowingTextView
//
//  Created by Семён C. Осипов on 15.08.2024.
//

import Foundation

extension NSItemProvider {
    var isUrl: Bool {
        return hasItemConformingToTypeIdentifier(.urlUTIType)
    }
    var isRTF: Bool {
        return hasItemConformingToTypeIdentifier(.rtfUTIType)
    }
    var isHTML: Bool {
        return hasItemConformingToTypeIdentifier(.htmlUTIType)
    }
    var isText: Bool {
        return hasItemConformingToTypeIdentifier(.textUTIType)
    }
}
