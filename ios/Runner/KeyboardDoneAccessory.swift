import ObjectiveC
import UIKit

final class KeyboardDoneAccessory {
  private static var didInstall = false
  fileprivate static var accessoryKey: UInt8 = 0
  private static weak var activeResponder: UIResponder?

  static func install() {
    guard !didInstall else { return }
    didInstall = true

    swizzleInputAccessoryView()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillShow),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
  }

  @objc private static func keyboardWillShow() {
    guard let responder = UIResponder.currentFirstResponder else { return }

    activeResponder = responder

    if let textField = responder as? UITextField {
      textField.inputAccessoryView = makeToolbar()
      textField.reloadInputViews()
      return
    }

    if let textView = responder as? UITextView {
      textView.inputAccessoryView = makeToolbar()
      textView.reloadInputViews()
      return
    }

    objc_setAssociatedObject(
      responder,
      &accessoryKey,
      makeToolbar(),
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
    responder.reloadInputViews()
  }

  private static func makeToolbar() -> UIToolbar {
    let toolbar = UIToolbar()
    toolbar.sizeToFit()

    toolbar.items = [
      UIBarButtonItem(
        barButtonSystemItem: .flexibleSpace,
        target: nil,
        action: nil
      ),
      UIBarButtonItem(
        barButtonSystemItem: .done,
        target: KeyboardDoneAccessory.self,
        action: #selector(doneTapped)
      ),
    ]

    return toolbar
  }

  @objc private static func doneTapped() {
    activeResponder?.resignFirstResponder()
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder),
      to: nil,
      from: nil,
      for: nil
    )
  }

  private static func swizzleInputAccessoryView() {
    guard
      let originalMethod = class_getInstanceMethod(
        UIResponder.self,
        #selector(getter: UIResponder.inputAccessoryView)
      ),
      let replacementMethod = class_getInstanceMethod(
        UIResponder.self,
        #selector(getter: UIResponder.keyboardDoneInputAccessoryView)
      )
    else {
      return
    }

    method_exchangeImplementations(originalMethod, replacementMethod)
  }
}

private extension UIResponder {
  private static weak var firstResponder: UIResponder?

  static var currentFirstResponder: UIResponder? {
    firstResponder = nil
    UIApplication.shared.sendAction(
      #selector(captureFirstResponder),
      to: nil,
      from: nil,
      for: nil
    )
    return firstResponder
  }

  @objc func captureFirstResponder() {
    UIResponder.firstResponder = self
  }

  @objc var keyboardDoneInputAccessoryView: UIView? {
    if let toolbar = objc_getAssociatedObject(
      self,
      &KeyboardDoneAccessory.accessoryKey
    ) as? UIView {
      return toolbar
    }

    return self.keyboardDoneInputAccessoryView
  }
}
