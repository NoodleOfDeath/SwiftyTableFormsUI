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

import SnapKit

/// Form table view cell for displaying a label and incremental stepper.
open class STFUFormStepperTableViewCell: STFUFormTableViewCell {
    
    // MARK: - UI Components
    
    /// Text field that displays the numerical value of this table view cell.
    fileprivate lazy var numberTextField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textColor = .blue
        textField.font = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
        textField.textAlignment = .center
        textField.returnKeyType = .done
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    ///  Stepper view container of this table view cell.
    fileprivate lazy var stepperView: UIView = {
        let view = UIView()
        view.addSubview(numberTextField)
        numberTextField.snp.makeConstraints({ (dims) in
            dims.left.equalTo(view)
            dims.centerY.equalTo(view)
        })
        view.addSubview(stepper)
        stepper.snp.makeConstraints({ (dims) in
            dims.left.equalTo(numberTextField.snp.right).offset(-10.0)
            dims.right.equalTo(view)
            dims.centerY.equalTo(view)
        })
        return view
    }()
    
    /// Stepper view of this table view cell.
    fileprivate lazy var stepper: UIStepper = {
        let stepper = UIStepper()
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.addTarget(self, action: #selector(stepperDidChangeValue(_:)), for: .valueChanged)
        return stepper
    }()
    
    // MARK: - UIView Methods
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        fieldContentView = stepperView
    }
    
    override open func updateContentView() {
        super.updateContentView()
        stepper.minimumValue = field.min
        stepper.maximumValue = field.max
        stepper.stepValue = field.stepSize
        loadValue()
    }
    
}

// MARK: - UITextFieldDelegate Methods
extension STFUFormStepperTableViewCell: UITextFieldDelegate {
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if var text = numberTextField.text {
            text = text.replacingOccurrences(of: field.units, with: "")
            text = text.replacingOccurrences(of: " ", with: "")
            field.value = Double(text) as NSObject? ?? field.value as? Double as NSObject? ?? field.min as NSObject?
            textField.resignFirstResponder()
        }
        return true
    }
    
    open func textFieldDidEndEditing(_ textField: UITextField) {
        guard var text = numberTextField.text else { return }
        text = text.replacingOccurrences(of: field.units, with: "")
        text = text.replacingOccurrences(of: " ", with: "")
        field.value = Double(text) as NSObject? ?? field.value as? Double as NSObject? ?? field.min as NSObject?
    }
    
}


// MARK: - Event Handler Methods
extension STFUFormStepperTableViewCell {
    
    /// Called when `stepper` changes value.
    ///
    /// - Parameters:
    ///     - stepper: The stepper that triggered this event.
    @objc
    fileprivate func stepperDidChangeValue(_ stepper: UIStepper) {
        if numberTextField.isFirstResponder {
            numberTextField.resignFirstResponder()
        }
        field.value = stepper.value as NSObject?
        loadValue()
    }
    
}

// MARK: - Instance Methods
extension STFUFormStepperTableViewCell {
    
    /// Loads the value of this field and updates the graphical display.
    fileprivate func loadValue() {
        
        guard let value = field.value as? Double else { return }
        
        if value < field.min {
            field.value = field.min as NSObject?
            loadValue()
            return
        } else if value > field.max {
            field.value = field.max as NSObject?
            loadValue()
            return
        }
        
        if stepper.value != value { stepper.value = value }
        
        numberTextField.text = String(format: "%." + String(format: "%ld", field.precision) + "f%@",
                                      value, field.units)
        
    }
    
}
