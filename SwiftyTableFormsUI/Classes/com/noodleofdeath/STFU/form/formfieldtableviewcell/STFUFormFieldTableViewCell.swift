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
    open var field = STFUField() { didSet { updateFieldDisplay() } }
    
    /// Whether or not this cell is checked.
    open var checked: Bool = false
    
    /// Whether or not this cell is enabled.
    open var enabled: Bool {
        get { return field.enabled }
        set {
            field.enabled = newValue
            disabledOverlayView.removeFromSuperview()
            if !newValue && disabledOverlay {
                addSubview(disabledOverlayView)
                disabledOverlayView.constrainToSuperview()
            }
            formViewController?.reload()
        }
    }
    
    /// Whether or not to use a disabled overlay.
    open var disabledOverlay: Bool { return true }
    
    /// Whether or not to use the long press popover display.
    open var longPressPopover: Bool { return true }
    
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
        stackView.addArrangedSubview(mainContentViewContainer)
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
    
    /// Main content view of this cell.
    open var mainContentView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            guard let mainContentView = mainContentView else { return }
            mainContentViewContainer.addConstrainedSubview(mainContentView)
        }
    }
    
    /// Main content view container of this cell.
    fileprivate lazy var mainContentViewContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    /// Disabled overlay view of this cell.
    fileprivate lazy var disabledOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray * 0.75
        return view
    }()
    
    /// Long press gesture recognizer of this table view cell.
    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didRecognize(longPressGesture:)))
    
    /// Popover view to display when the user long presses.
    fileprivate lazy var popoverView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.alpha = 0.0
        view.layer.borderWidth = 2.0
        view.layer.borderColor = UIColor.black.cgColor
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.addArrangedSubview(popoverTitleLabel)
        popoverTitleLabel.snp.makeConstraints({ (dims) in
            dims.height.equalTo(20.0)
        })
        stackView.addArrangedSubview(popoverValueLabel)
        view.addConstrainedSubview(stackView, 5.0, 10.0, -5.0, -10.0)
        return view
    }()
    
    /// Popover title label for field title.
    fileprivate lazy var popoverTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = .black
        label.font = .systemFont(ofSize: 10.0)
        label.backgroundColor = .lightGray
        return label
    }()
    
    /// Popover label for field contents.
    fileprivate lazy var popoverValueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .gray
        return label
    }()
    
    // MARK: UIView Methods
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        contentView.addConstrainedSubview(layoutView, 0.0, 10.0, 0.0, -10.0)
        updateFieldDisplay()
        if longPressPopover {
            titleLabel.addGestureRecognizer(longPressGesture)
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fieldDidChange(_:)),
            name: STFUField.didChangeNotification,
            object: field
        )
    }
    
    /// Updates the metadata of this field and its graphical display.
    open func updateFieldDisplay() {
        iconView.snp.updateConstraints { (dims) in
            dims.width.equalTo(field.image != nil ? iconView.snp.height : 0.0)
        }
        titleLabel.text = field.title
        let title = field.title ?? ""
        titleLabel.snp.updateConstraints { (dims) in
            dims.width.equalTo(title.width(withAttributes: [.font: titleLabel.font]))
        }
        checked = field.checked
        popoverTitleLabel.text = field.title
        popoverValueLabel.text = field.value as? String
    }
    
    /// Draws focus to this field. Subclasses must override and implement
    /// this method or nothing will happen when it is called.
    open func focus() {
        
    }
    
}

// MARK: - Event Handler Methods
extension STFUFormTableViewCell {
    
    /// Event handler for a long press gesture.
    @objc
    open func didRecognize(longPressGesture: UILongPressGestureRecognizer) {
        
        switch longPressGesture.state {
            
        case .began:
            superview?.addSubview(popoverView)
            popoverView.snp.makeConstraints { (dims) in
                dims.left.equalTo(self).offset(10.0)
                dims.right.equalTo(self).offset(-10.0)
                dims.bottom.equalTo(self.snp.top).offset(-5.0)
                dims.height.equalTo(50.0)
            }
            UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration)) {
                self.popoverView.alpha = 1.0
            }
            break
            
        case .ended, .failed, .cancelled:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration), animations: {
                    self.popoverView.alpha = 0.0
                }) { _ in
                    self.popoverView.removeFromSuperview()
                }
            }
            
        default:
            break
            
        }
        
    }
    
    /// Called when `field` is changed.
    ///
    /// - Parameters:
    ///     - notification: containing information about the triggered event.
    @objc
    open func fieldDidChange(_ notification: Notification) {
        updateFieldDisplay()
    }
    
    /// Called when `form` is changed.
    ///
    /// - Parameters:
    ///     - notification: containing information about the triggered event.
    @objc
    open func formDidChange(_ notification: Notification) {
        updateFieldDisplay()
    }
    
}

/// Specifications for an option table view controller delegate.
@objc
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
