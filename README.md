# ARGrowingTextView

[![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![iOS 13+](https://img.shields.io/badge/iOS-13%2B-blue.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Auto-growing multi-line `UITextView` with built-in Markdown support. Similar to the text input field in iMessage — the view automatically adjusts its height as the user types.

Powered by [ARMarkdownTextStorage](https://github.com/AppleArealidea/ARMarkdownTextStorage) for real-time Markdown rendering.

## Features

- **Auto-resizing** — height grows and shrinks with content, constrained by min/max lines or explicit point values
- **Height change animation** — smooth animated transitions with `ARAnimationContext` to synchronize surrounding layout changes
- **Placeholder** — built-in placeholder label with customizable color
- **Markdown** — live rendering of **bold**, *italic*, ~~strikethrough~~, and underline via `MarkdownTextStorage`
- **Smart paste** — RTF, HTML, plain text, and URL paste automatically converted to Markdown symbols
- **Smart copy** — copies selected text with Markdown formatting preserved
- **Style menu** — context menu actions for Bold, Italic, Underline, and Strikethrough on selected text
- **Image paste** — images from the pasteboard forwarded through `userDidPaste(images:)` delegate callback
- **Dynamic Type** — responds to `UIContentSizeCategory` changes and updates font accordingly
- **UITextView proxy** — all commonly used `UITextView` properties exposed directly on `ARGrowingTextView`

## Requirements

- iOS 13.0+
- Swift 5.10+
- [ARMarkdownTextStorage](https://github.com/AppleArealidea/ARMarkdownTextStorage) >= 2.0.0 (resolved automatically)

## Installation

### Swift Package Manager

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/AppleArealidea/ARGrowingTextView.git",
             .upToNextMajor(from: "1.0.0"))
]
```

Then add `"ARGrowingTextView"` to the target's `dependencies` array.

Or in Xcode: **File → Add Package Dependencies…** and paste the repository URL.

## Usage

### Basic setup

```swift
import ARGrowingTextView

let textView = ARGrowingTextView()
textView.minNumberOfLines = 1
textView.maxNumberOfLines = 6
textView.placeholder = "Type a message…"
textView.font = .preferredFont(forTextStyle: .body)
textView.delegate = self
```

### Height constraints

You can limit growth by number of lines:

```swift
textView.minNumberOfLines = 1
textView.maxNumberOfLines = 5
```

Or by explicit point values:

```swift
textView.minHeight = 36
textView.maxHeight = 200
```

### Animated height changes

Enable or disable animation and set its duration:

```swift
textView.animateHeightChange = true   // default
textView.animationDuration = 0.1      // default
```

Use `ARAnimationContext` in the delegate to run your own animations in sync with the height transition:

```swift
func growingTextView(_ growingTextView: ARGrowingTextView,
                     changeHeightWith diff: CGFloat,
                     animationContext: ARAnimationContext) {
    animationContext.animate {
        // adjust your bottom constraint, table view inset, etc.
        self.bottomConstraint.constant += diff
        self.view.layoutIfNeeded()
    }
}
```

### Handling pasted images

```swift
func userDidPaste(images: [UIImage]) {
    // process pasted images
}
```

### Accessing the internal UITextView

For properties not directly proxied, use `internalTextView`:

```swift
textView.internalTextView.autocorrectionType = .no
```

## Delegate

`ARGrowingTextViewDelegate` provides the following optional callbacks:

| Method | Description |
|---|---|
| `growingTextViewShouldBeginEditing(_:)` | Whether editing should begin |
| `growingTextViewShouldEndEditing(_:)` | Whether editing should end |
| `growingTextViewDidBeginEditing(_:)` | Editing started |
| `growingTextViewDidEndEditing(_:)` | Editing ended |
| `growingTextView(_:shouldChangeTextIn:replacementText:)` | Intercept text changes |
| `growingTextViewDidChange(_:)` | Text content changed |
| `growingTextView(_:willChangeHeight:)` | Height is about to change |
| `growingTextView(_:changeHeightWith:animationContext:)` | Height is changing — use the context to add synchronized animations |
| `growingTextView(_:didChangeHeight:)` | Height change completed |
| `growingTextViewDidChangeSelection(_:)` | Text selection changed |
| `growingTextViewShouldReturn(_:)` | Return key tapped — return `true` to resign first responder |
| `userDidPaste(images:)` | User pasted images from the pasteboard |

## Migrating from HPGrowingTextView

ARGrowingTextView preserves the same architectural approach (a `UIView` wrapping an internal `UITextView`) and keeps familiar API names, so migration is mostly mechanical.

### What stays the same

| HPGrowingTextView (Obj-C) | ARGrowingTextView (Swift) |
|---|---|
| `maxNumberOfLines` / `minNumberOfLines` | `maxNumberOfLines` / `minNumberOfLines` |
| `maxHeight` / `minHeight` | `maxHeight` / `minHeight` |
| `animateHeightChange` | `animateHeightChange` |
| `animationDuration` | `animationDuration` |
| `.internalTextView` | `.internalTextView` |
| `text`, `font`, `textColor`, `textAlignment`, `selectedRange`, `editable`, `dataDetectorTypes`, `returnKeyType` | Same — proxied directly |
| All `growingTextView…` delegate methods | Same names, Swift syntax |

### What changed

| Change | Details |
|---|---|
| **Language** | Objective-C → Swift 5.10+ |
| **Min deployment** | iOS 4+ → iOS 13+ |
| **Installation** | CocoaPods → Swift Package Manager |
| **Layout** | Frame-based → Auto Layout (add as subview and pin with constraints) |
| **Height animation callback** | `willChangeHeight:` was called *inside* the animation block. Now use `changeHeightWith:animationContext:` and call `animationContext.animate { … }` to synchronize your layout changes. |
| **Delegate protocol** | `HPGrowingTextViewDelegate` → `ARGrowingTextViewDelegate` |

### What's new

- **Markdown** — live bold, italic, strikethrough, and underline rendering via `MarkdownTextStorage`
- **Smart paste / copy** — RTF, HTML, and URL paste converted to Markdown; copy preserves formatting
- **Style menu** — context menu actions (Bold, Italic, Underline, Strikethrough) on selected text
- **Image paste** — `userDidPaste(images:)` delegate callback
- **Placeholder** — built-in placeholder label with customizable color
- **Dynamic Type** — automatic font updates on `UIContentSizeCategory` changes

### Quick example

```diff
- #import "HPGrowingTextView.h"
+ import ARGrowingTextView

- HPGrowingTextView *textView = [[HPGrowingTextView alloc] initWithFrame:rect];
- textView.minNumberOfLines = 1;
- textView.maxNumberOfLines = 5;
+ let textView = ARGrowingTextView()
+ textView.minNumberOfLines = 1
+ textView.maxNumberOfLines = 5

  // Height animation
- - (void)growingTextView:(HPGrowingTextView *)gTV willChangeHeight:(float)height {
-     [UIView animateWithDuration:0.1 animations:^{
-         // adjust layout
-     }];
- }
+ func growingTextView(_ growingTextView: ARGrowingTextView,
+                      changeHeightWith diff: CGFloat,
+                      animationContext: ARAnimationContext) {
+     animationContext.animate {
+         self.bottomConstraint.constant += diff
+         self.view.layoutIfNeeded()
+     }
+ }
```

## Acknowledgments

ARGrowingTextView is inspired by [HPGrowingTextView](https://github.com/HansPinckaers/GrowingTextView) 
by Hans Pinckaers — a pioneering Objective-C library (2011, 2000+ stars) that introduced the concept 
of an auto-growing UITextView for iOS. The original project has been archived since 2019.

ARGrowingTextView is a modern reimagining in Swift, adding Markdown support, smart paste/copy, 
style menus, image handling, Dynamic Type, and full Auto Layout integration.

## License

[MIT](LICENSE) © 2023 Areal
