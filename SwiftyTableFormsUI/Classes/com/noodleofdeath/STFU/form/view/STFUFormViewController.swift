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

/// Specifications for a form view controller delegate.
@objc
public protocol STFUFormViewControllerDelegate: class {

    @objc optional
    func formViewController(_ formViewController: STFUFormViewController, didChange form: STFUForm)
    
    @objc optional
    func formViewController(_ formViewController: STFUFormViewController, didSubmit form: STFUForm)
    
}

/// View controller that displays a form containing sections and fields.
@objc
open class STFUFormViewController: UIViewController {

    // MARK: - Instance Properties
    
    /// Delegate of this form view controller.
    open weak var delegate: STFUFormViewControllerDelegate?
    
    /// Data source from which to retrieve and update.
    open var form: STFUForm {
        didSet {
            NotificationCenter.default.removeObserver(self,
                                                      name: STFUForm.didChangeNotification,
                                                      object: oldValue)
            loadForm()
        }
    }
    
    /// Name of this form table view controller.
    open var name: String? { return form.name }
    
    /// Cancel bar button item of this form table view controller.
    open var cancelBarButtonItem: UIBarButtonItem? {
        didSet {
            cancelBarButtonItem?.target = self
            cancelBarButtonItem?.action = #selector(didPress(cancelBarButtonItem:))
            navigationItem.leftBarButtonItem = cancelBarButtonItem
        }
    }
    
    /// Done button convenience getter/setter.
    open var submitBarButtonItem: UIBarButtonItem? {
        didSet {
            submitBarButtonItem?.target = self
            submitBarButtonItem?.action = #selector(didPress(submitBarButtonItem:))
            navigationItem.rightBarButtonItem = submitBarButtonItem
            submitBarButtonItem?.isEnabled = form.canSubmit
        }
    }
    
    /// Data contained in `form`.
    open var formData: [String: Any] { return form.fields }
    
    /// Original form formData before changes are made by the user.
    open fileprivate (set) lazy var originalFormData = formData

    /// Table view in which to display each field of the `form` as a custom
    /// UITableViewCell.
    fileprivate lazy var tableView: UITableView = {

        let tableView = UITableView(frame: .zero, style: .grouped)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(
            STFUFormButtonTableViewCell.self,
            forCellReuseIdentifier: STFUFieldType.button.rawValue)
        tableView.register(
            STFUFormCheckboxTableViewCell.self,
            forCellReuseIdentifier: STFUFieldType.checkbox.rawValue)
        tableView.register(
            STFUFormColorPickerTableViewCell.self,
            forCellReuseIdentifier: STFUFieldType.color.rawValue)
        tableView.register(
            STFUFormTableViewCell.self,
            forCellReuseIdentifier: STFUFieldType.hidden.rawValue)
        tableView.register(
            STFUFormPickerTableViewCell.self,     
            forCellReuseIdentifier: STFUFieldType.picker.rawValue)
        tableView.register(
            STFUFormRadioTableViewCell.self,      
            forCellReuseIdentifier: STFUFieldType.radio.rawValue)
        tableView.register(
            STFUFormSliderTableViewCell.self,     
            forCellReuseIdentifier: STFUFieldType.slider.rawValue)
        tableView.register(
            STFUFormStepperTableViewCell.self,    
            forCellReuseIdentifier: STFUFieldType.stepper.rawValue)
        tableView.register(
            STFUFormTextTableViewCell.self,       
            forCellReuseIdentifier: STFUFieldType.text.rawValue)
        tableView.register(
            STFUFormTitleTableViewCell.self,  
            forCellReuseIdentifier: STFUFieldType.title.rawValue)
        tableView.register(
            STFUFormWebViewTableViewCell.self,
            forCellReuseIdentifier: STFUFieldType.url.rawValue)
        
        tableView.register(
            STFUFormSeparatorTableViewCell.self, 
            forCellReuseIdentifier: STFUFieldType.separator.rawValue)
        
        return tableView
        
    }()

    // MARK: - Constructor Methods
    
    required public init?(coder aDecoder: NSCoder) {
        form = STFUForm()
        super.init(coder: aDecoder)
        generateDefaultNavigationItems()
    }
    
    /// Constructs a new form view controller from a given form and
    /// initialized with a given view.
    ///
    /// - Parameters:
    ///     - form: to initialize this form table view controller with.
    ///     - view: to initialize this form table view controller with.
    public init(form: STFUForm, view: UIView? = nil) {
        self.form = form
        super.init(nibName: nil, bundle: nil)
        self.view ?= view
        generateDefaultNavigationItems()
    }
    
    /// Constructs a new form view controller from a given bundle.
    ///
    /// - Parameters:
    ///     - path: of the bundle to initialize this form table view controller
    /// with.
    ///     - view: to initialize this form table view controller with.
    convenience public init?(path: String, view: UIView? = nil) {
        guard let form = STFUForm(path: path) else { return nil }
        self.init(form: form, view: view)
    }
    
    // MARK: - UIViewController Methods
 
    override open func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.addConstrainedSubview(tableView)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didRecognize(singleTap:)))
        gesture.cancelsTouchesInView = false
        view.addGestureRecognizer(gesture)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: NSNotification.Name.UIKeyboardWillChangeFrame,
            object: nil)
        
        loadForm()
        
    }
    
}

// MARK: - Instance Methods
extension STFUFormViewController {
    
    open func generateDefaultNavigationItems() {
        cancelBarButtonItem = UIBarButtonItem(title: "cancel".capitalized,
                                              style: .plain,
                                              target: self,
                                              action: #selector(didPress(cancelBarButtonItem:)))
        navigationItem.leftBarButtonItem = cancelBarButtonItem
        submitBarButtonItem = UIBarButtonItem(title: "done".capitalized,
                                              style: .plain,
                                              target: self,
                                              action: #selector(didPress(submitBarButtonItem:)))
        navigationItem.rightBarButtonItem = submitBarButtonItem
        submitBarButtonItem?.isEnabled = form.canSubmit
    }
    
    /// Returns the value of the form field associated with a given field name.
    ///
    /// - Parameters:
    ///     - fieldName: Unique name of the field for which to retrieve
    /// a value from.
    /// - Returns: The value of the form field associated with a given field 
    /// name, or `nil` if no such form field exists for the given field name.
    open func value(ofFieldNamed fieldName: String) -> Any? {
        return form[fieldName]
    }
    
    /// Sets the value of the form field object associated with a given unique 
    /// field name.
    ///
    /// - Parameters:
    ///     - value: Value to set for the field.
    ///     - fieldName: Name of the field to modify.
    open func set(_ value: Any?, ofFieldNamed fieldName: String) {
        form[fieldName] = value
    }
    
    /// Returns the form field object located at a given index path.
    ///
    /// - Parameters:
    ///     - indexPath: Index path of the field to retrieve.
    /// - Returns: the form field object located at a given index path
    open func field(at indexPath: IndexPath) -> STFUField {
        let fields = form.fields(in: indexPath.section)
        return fields[indexPath.row]
    }
    
    /// Presents this form table view controller inside of a navigation controller
    /// modally or from a bar button item and with a default cancel button.
    ///
    /// - Note: The object calling this method should also be responsible
    /// for setting any additional navigation bar buttons and toolbar items.
    /// - Parameters:
    ///     - presentingViewController: that will present this form view
    /// controller.
    ///     - barButtonItem: from which to display this form table view controller
    /// on large screen devices. Passing `nil` for this parameter will cause
    /// the form view controller to be displayed modally. Default is `nil`.
    ///     - animated: `true` to animate display of this form view
    /// controller; `false` to display instantly. Default is `true`.
    ///     - completion: The block to execute after the presentation
    /// finishes. This block has no return value and takes no parameters.
    /// Default is `nil`.
    @objc
    open func present(in presentingViewController: UIViewController?,
                      from barButtonItem: UIBarButtonItem? = nil,
                      permittedArrowDirections:  UIPopoverArrowDirection = .any,
                      animated: Bool,
                      completion: (() -> ())? = nil) {
        let nav = asNavigationController
        if let barButtonItem = barButtonItem {
            nav.modalPresentationStyle = .popover
            let presentationController = nav.popoverPresentationController
            presentationController?.permittedArrowDirections = permittedArrowDirections
            presentationController?.barButtonItem = barButtonItem
        }
        presentingViewController?.present(nav, animated: animated, completion: completion)
    }

    /// Can be called when the user is done with this form an wants to submit
    /// it.
    open func submit() {
        guard form.canSubmit else { return }
        delegate?.formViewController?(self, didSubmit: form)
    }
    
    open func reload() {
        tableView.reloadData()
    }

    /// Sets the title of this form table view controller to the title of its `form`
    /// and updates the table view.
    fileprivate func loadForm() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataDidChange(_:)),
            name: STFUForm.didChangeNotification,
            object: form)
        title = form.title ?? form.name ?? title
        submitBarButtonItem?.isEnabled = form.canSubmit
        tableView.reloadData()
    }
    
}

// MARK: - UITableViewDataSource Methods
extension STFUFormViewController: UITableViewDataSource {
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return form.sections.count
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return form.fields(in: section).count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let field = self.field(at: indexPath)
        let _cell = tableView.dequeueReusableCell(withIdentifier: field.type.rawValue, for: indexPath)
        
        guard let cell = _cell as? STFUFormTableViewCell else { return _cell }

        cell.formViewController = self
        cell.field = field
        
        return cell
        
    }
    
    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return form.sections[section].header
    }
    
    open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return form.sections[section].footer
    }
    
}

// MARK: - UITableViewDelegate Methods
extension STFUFormViewController: UITableViewDelegate {
    
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? STFUFormTableViewCell else { return }
        cell.formViewController = self
        cell.updateFieldDisplay()
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let field = self.field(at: indexPath)
        return field.type == .hidden ? 0.0 : field.type == .separator ? 2.0 : 44.0
    }
    
    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let field = self.field(at: indexPath)
        return [.picker, .radio, .url].contains(field.type)
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let field = self.field(at: indexPath)
        
        switch field.type {
            
        case .picker:
            
            let optionTable = STFUFormOptionTableViewController(style: .grouped)
            optionTable.delegate = self
            optionTable.field = field
            
            navigationController?.pushViewController(optionTable, animated: true)
            
            break
            
        case .url:
            
            guard let path = field.value as? String, let url = URL(string: path) else { return }
            
            let webView = UIWebView()
            webView.loadRequest(URLRequest(url: url))
            
            let viewController = UIViewController()
            viewController.view.addConstrainedSubview(webView)
            navigationController?.pushViewController(viewController, animated: true)
            
            break
            
        default:
            break
            
        }
        
    }
    
}

// MARK: - UITextFieldDelegate Methods
extension STFUFormViewController: UITextFieldDelegate {
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
}

// MARK: - STFUFieldViewControllerDelegate Methods
extension STFUFormViewController: STFUFieldViewControllerDelegate {
    
    open func optionTableDidResign(_ optionTable: STFUFormOptionTableViewController) {
        if let field = optionTable.field {
            form.field(field, didChangeValueFrom: nil)
        }
        tableView.reloadData()
    }
    
}

// MARK: - Event Handler Methods
extension STFUFormViewController {
    
    /// Called when a single tap gesture is recognized.
    ///
    /// - Parameters:
    ///     - gesture: Tap gesture recognizer that triggered this event.
    @objc
    open func didRecognize(singleTap gesture: UITapGestureRecognizer) {
        UIApplication.shared.keyWindow?.endEditing(true)
    }
    
    /// Called when the cancel bar button item is pressed.
    ///
    /// - Parameters:
    ///     - cancelBarButtonItem: that triggered this event.
    @objc
    open func didPress(cancelBarButtonItem: UIBarButtonItem) {
        dismiss(animated: true) {}
    }
    
    /// Called when the submit bar button item is pressed.
    ///
    /// - Parameters:
    ///     - submitBarButtonItem: that triggered this event.
    @objc
    open func didPress(submitBarButtonItem: UIBarButtonItem) {
        submit()
    }
    
    /// Called when the keyboard changes frame.
    ///
    /// - Parameters:
    ///     - notification: containing information about the triggered event.
    @objc
    open func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        tableView.snp.updateConstraints { (dims) in
            dims.top.equalTo(view)
            dims.left.equalTo(view)
            dims.bottom.equalTo(view).offset(UIScreen.main.bounds.height - keyboardFrame.origin.y)
            dims.right.equalTo(view)
        }
        UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration)) {
            self.view.layoutIfNeeded()
        }
    }
    
    /// Called when the `form` object of this form table view controller is modified.
    ///
    /// - Parameters:
    ///     - notification: containing information about the triggered event.
    @objc
    open func dataDidChange(_ notification: Notification) {
        if form.sectionsNeedDisplay {
            reload()
        }
        originalFormData = formData
        submitBarButtonItem?.isEnabled = form.canSubmit
        delegate?.formViewController?(self, didChange: form)
    }
    
}
