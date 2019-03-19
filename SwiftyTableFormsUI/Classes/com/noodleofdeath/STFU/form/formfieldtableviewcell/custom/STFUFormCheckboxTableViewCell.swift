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

/// Form table view cell for displaying a label and switch checkbox.
open class STFUFormCheckboxTableViewCell: STFUFormTableViewCell {
    
    fileprivate lazy var checkboxSwitch: UISwitch = {
        let checkboxSwitch = UISwitch()
        checkboxSwitch.translatesAutoresizingMaskIntoConstraints = false
        checkboxSwitch.addTarget(self, action: #selector(checkboxSwitchDidChangeState(_:)), for: .touchUpInside)
        return checkboxSwitch
    }()
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        fieldContentView = checkboxSwitch
    }
    
    override open func updateContentView() {
        super.updateContentView()
        guard let value = field.value as? Bool else { return }
        checkboxSwitch.isOn = value
        field.checked = value
    }
        
    @objc
    fileprivate func checkboxSwitchDidChangeState(_ checkboxSwitch: UISwitch) {
        field.value = checkboxSwitch.isOn as NSObject?
    }
    
}


