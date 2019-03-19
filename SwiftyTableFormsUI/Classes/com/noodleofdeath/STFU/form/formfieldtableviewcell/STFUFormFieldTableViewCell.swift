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

/// Base implementation for a field cell for display in a table view.
@objc
open class STFUFormTableViewCell: UITableViewCell {
    
    // MARK: - Instance Properties
    
    /// STFUForm view controller of this cell.
    open weak var formViewController: STFUFormViewController?
    
    /// STFUForm of this cell's form view controller.
    open var form: STFUForm? { return formViewController?.form }
    
    /// Navigation controller of this cell's form view controller.
    open var navigationController: UINavigationController? {
        return formViewController?.navigationController
    }
    
    /// Field of this cell.
    open var field = STFUField() { didSet { updateContentView() } }
    
    /// Whether or not this cell is checked.
    open var checked: Bool = false
    
    /// Whether or not this cell is enabled.
    open var enabled: Bool {
        get { return field.enabled }
        set {
            field.enabled = newValue
            disabledOverlay.removeFromSuperview()
            if !newValue && usesDisabledOverlay {
                addSubview(disabledOverlay)
                disabledOverlay.constrainToSuperview()
            }
            formViewController?.reload()
        }
    }
    
    /// Whether or not to use a disabled overlay.
    open var usesDisabledOverlay: Bool { return true }
    
    // MARK: - UI Components
    
    /// Layout view of this table view cell.
    open fileprivate (set) lazy var layoutView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 10.0
        stackView.addArrangedSubview(iconView)
        iconView.snp.makeConstraints({ (dims) in
            dims.width.equalTo(0.0)
        })
        stackView.addArrangedSubview(titleLabel)
        titleLabel.snp.makeConstraints { (dims) in
            dims.width.equalTo(field.title?.width(withAttributes: [.font: titleLabel.font]) ?? 0.0)
        }
        stackView.addArrangedSubview(fieldContentViewContainer)
        return stackView
    }()
    
    open fileprivate (set) lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = field.image
        return imageView
    }()
    
    /// Title label of this cell.
    open fileprivate (set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = field.title
        label.adjustsFontSizeToFitWidth = true
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        return label
    }()
    
    /// Field content view of this cell.
    open var fieldContentView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let fieldContentView = fieldContentView else { return }
            fieldContentViewContainer.addConstrainedSubview(fieldContentView)
        }
    }
    
    /// Field content view container of this cell.
    fileprivate lazy var fieldContentViewContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    /// Disabled overlay view of this cell.
    fileprivate lazy var disabledOverlay: UIView = {
        let disabledOverlay = UIView()
        disabledOverlay.backgroundColor = .lightGray * 0.75
        return disabledOverlay
    }()
    
    // MARK: UIView Methods
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        contentView.addConstrainedSubview(layoutView, 0.0, 10.0, 0.0, -10.0)
        updateContentView()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fieldDidChange(_:)),
            name: STFUField.didChangeNotification,
            object: field
        )
    }
    
    /// Updates the metadata of this field and its graphical display.
    open func updateContentView() {
        iconView.snp.updateConstraints { (dims) in
            dims.width.equalTo(field.image != nil ? iconView.snp.height : 0.0)
        }
        titleLabel.text = field.title
        let title = field.title ?? ""
        titleLabel.snp.updateConstraints { (dims) in
            dims.width.equalTo(title.width(withAttributes: [.font: titleLabel.font]))
        }
        checked = field.checked
    }
    
    /// Draws focus to this field. Subclasses must override and implement
    /// this method or nothing will happen when it is called.
    open func focus() {
        
    }
    
}

// MARK: - Event Handler Methods
extension STFUFormTableViewCell {
    
    /// Called when `field` is changed.
    ///
    /// - Parameters:
    ///     - notification: containing information about the triggered event.
    @objc
    open func fieldDidChange(_ notification: Notification) {
        updateContentView()
    }
    
    /// Called when `form` is changed.
    ///
    /// - Parameters:
    ///     - notification: containing information about the triggered event.
    @objc
    open func formDidChange(_ notification: Notification) {
        updateContentView()
    }
    
}

/// Specifications for an option table view controller delegate.
@objc(STFUFieldViewControllerDelegate)
public protocol STFUFieldViewControllerDelegate: class {
    
    /// Called when an form field view controller will disappear.
    ///
    /// - Parameters:
    ///     - viewController: that will disappear.
    @objc optional
    func formFieldViewControllerWillDisappear(_ viewController: STFUFieldViewController)
    
}

open class STFUFieldViewController: UIViewController {
    
    // MARK: - Instance Properties
    
    /// Delegate of this accessory view controller.
    open weak var delegate: STFUFieldViewControllerDelegate?
    
    /// Field of this accessory view controller.
    open var field: STFUField?
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.formFieldViewControllerWillDisappear?(self)
    }
    
}
