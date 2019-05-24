//
// The MIT License (MIT)
//
// Copyright © 2019 NoodleOfDeath. All rights reserved.
// NoodleOfDeath
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

/// Form table view cell for displaying a label and color selection.
open class STFUFormColorPickerTableViewCell: STFUFormTableViewCell {
    
    var rgbValue: UInt? {
        get {
            if let value = field.value as? Int { return UInt(value) }
            return field.value as? UInt
        }
        set { field.value = newValue }
    }

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.addArrangedSubview(colorTextField)
        colorTextField.snp.makeConstraints({ (dims) in
            dims.height.equalTo(stackView)
        })
        stackView.addArrangedSubview(colorButton)
        colorButton.snp.makeConstraints({ (dims) in
            dims.width.equalTo(colorButton.snp.height)
        })
        return stackView
    }()
    
    lazy var colorTextField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.textAlignment = .center
        textField.textColor = .gray
        textField.autocorrectionType = .no
        return textField
    }()
    
    lazy var colorButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.textAlignment = .center
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 5.0
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(didPress(colorButton:)), for: .touchUpInside)
        return button
    }()
    
    lazy var colorPicker: STFUFormColorPickerViewController = {
        let colorPicker = STFUFormColorPickerViewController()
        colorPicker.delegate = self
        return colorPicker
    }()
    
    ///
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        mainContentView = stackView
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textFieldDidChange(_:)),
            name: NSNotification.Name.UITextFieldTextDidChange,
            object: colorTextField)
    }
    
    override open func updateFieldDisplay() {
        super.updateFieldDisplay()
        guard let rgbValue = rgbValue else { return }
        if colorTextField.text == nil || colorTextField.text == "" {
            colorTextField.text = String(format: "#%06X", rgbValue)
        }
        colorButton.backgroundColor = UIColor(rgbValue)
    }

}

extension STFUFormColorPickerTableViewCell: UITextFieldDelegate {
    
    
    
}

extension STFUFormColorPickerTableViewCell: STFUFormColorPickerViewControllerDelegate {
    
    public func colorPickerViewController(_ colorPickerViewController: STFUFormColorPickerViewController, didSelectColor rgbValue: UInt) {
        self.rgbValue = rgbValue
        self.colorTextField.text = String(format: "#%06X", rgbValue)
    }
    
}

extension STFUFormColorPickerTableViewCell {
    
    @objc
    open func textFieldDidChange(_ notification: Notification) {
        guard let color = colorTextField.text?.replacingOccurrences(of: "#", with: "", options: .regularExpression) else { return }
        if let rgbValue = UInt(color, radix: 16) {
            self.rgbValue = rgbValue
        }
    }
    
    @objc
    open func didPress(colorButton: UIButton) {
        colorPicker.rgbValue = rgbValue
        navigationController?.pushViewController(colorPicker, animated: true)
    }
    
}

public protocol STFUFormColorPickerViewControllerDelegate: class {
    
    func colorPickerViewController(_ colorPickerViewController: STFUFormColorPickerViewController, didSelectColor rgbValue: UInt)
    
}

///
open class STFUFormColorPickerViewController: UIViewController {
    
    open weak var delegate: STFUFormColorPickerViewControllerDelegate?
    
    open var rgbValue: UInt? {
        didSet {
            guard let rgbValue = rgbValue else { return }
            delegate?.colorPickerViewController(self, didSelectColor: rgbValue)
            red = (rgbValue & 0xFF0000) >> 16
            green = (rgbValue & 0x00FF00) >> 8
            blue = rgbValue & 0x0000FF
        }
    }
    
    open var red: UInt = 0
    
    open var blue: UInt = 0
    
    open var green: UInt = 0
    
    lazy var colorPicker: ColorPicker = {
        let colorPicker = ColorPicker()
        return colorPicker
    }()
    
    lazy var redTextView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.layer.borderColor = UIColor.black.cgColor
        textView.layer.borderWidth = 2.0
        return textView
    }()
    
    lazy var greenTextView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.layer.borderColor = UIColor.black.cgColor
        textView.layer.borderWidth = 2.0
        return textView
    }()
    
    lazy var blueTextView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.layer.borderColor = UIColor.black.cgColor
        textView.layer.borderWidth = 2.0
        return textView
    }()
    
    override open func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10.0
        
        redTextView.text = String(format: "%d", red)
        greenTextView.text = String(format: "%d", green)
        blueTextView.text = String(format: "%d", blue)
        
        stackView.addArrangedSubview(colorPicker)
        colorPicker.snp.makeConstraints { (dims) in
            dims.height.equalTo(stackView.width)
        }
        
        stackView.addArrangedSubview(redTextView)
        redTextView.snp.makeConstraints { (dims) in
            dims.height.equalTo(50.0)
        }
        stackView.addArrangedSubview(greenTextView)
        greenTextView.snp.makeConstraints { (dims) in
            dims.height.equalTo(50.0)
        }
        stackView.addArrangedSubview(blueTextView)
        blueTextView.snp.makeConstraints { (dims) in
            dims.height.equalTo(50.0)
        }
        
        view.addConstrainedSubview(stackView)
        
    }
    
}

extension STFUFormColorPickerViewController: UITextViewDelegate {
    
    open func textViewDidChange(_ textView: UITextView) {
        if
            let red = UInt(redTextView.text),
            let green = UInt(greenTextView.text),
            let blue = UInt(blueTextView.text) {
            self.rgbValue = (red << 16) + (green << 8) + blue
        }
    }
    
}

class ColorPicker: UIView {
    
    override func draw(_ rect: CGRect) {
        
        super.draw(rect)
    }
        
}
