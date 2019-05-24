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

/// Form table view cell for displaying a label and radio button.
open class STFUFormRadioTableViewCell: STFUFormTableViewCell {

    // MARK: - Instance Properties
    
    override open var checked: Bool {
        didSet {
            accessoryType = checked ? .checkmark : .none
        }
    }
    
    // MARK: - UIView Methods
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    
    // MARK: - FieldCell Methods
    
    override open func updateFieldDisplay() {
        super.updateFieldDisplay()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkDidChange(_:)),
            name: STFUField.didChangeNotification,
            object: field)
        checked = field.checked
    }
    
    // MARK: - Event Handler Methods
    
    override open func setSelected(_ selected: Bool, animated: Bool) {

        super.setSelected(selected, animated: animated)
        
        accessoryType = selected ? .checkmark : .none
        
        if selected {
        
            field.checked = true
            
            NotificationCenter.default.removeObserver(
                self,
                name: STFUField.didChangeNotification,
                object: field)
            
            guard let fieldMap = form?.fieldMap else { return }
            fieldMap.forEach {
                guard $0.value != self.field && $0.value.name == self.field.name else { return }
                $0.value.checked = false
            }
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(checkDidChange(_:)),
                name: STFUField.didChangeNotification,
                object: field)
            
        }
        
    }
    
    // MARK: - Notification Handler Methods
    
    /// Called when the value of `field` is changed.
    ///
    /// - Parameters:
    ///     - notification: Notification object containing information
    /// about the triggered event.
    @objc
    fileprivate func checkDidChange(_ notification: Notification) {
        checked = field.checked
    }
    
}
