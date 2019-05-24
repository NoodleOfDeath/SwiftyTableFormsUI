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

/// Form table view cell for displaying a label and selected option that can
/// be changed from a set of possible options.
open class STFUFormPickerTableViewCell: STFUFormTableViewCell {
    
    // MARK: - UI Components
    
    /// Option view contrainer of this table view cell.
    fileprivate lazy var optionView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(optionLabel)
        optionLabel.snp.makeConstraints({ (dims) in
            dims.left.equalTo(view)
            dims.right.equalTo(view).offset(-20.0)
            dims.centerY.equalTo(view)
        })
        return view
    }()
    
    /// Option label of this table view cell.
    fileprivate lazy var optionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.textColor = .gray
        return label
    }()
    
    // MARK: - UIView Methods
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        accessoryType = .disclosureIndicator
        titleLabel.textAlignment = .right
        titleLabel.textColor = .gray
        mainContentView = optionView
    }
    
    // MARK: - STFUFormTableViewCell Methods
    
    override open func updateFieldDisplay() {
        super.updateFieldDisplay()
        guard let key = field.value as? String else { return }
        guard let option = field.options[key] else { return }
        titleLabel.text = option.title
        titleLabel.font = option.font
        titleLabel.textColor = option.color ?? .gray
        titleLabel.backgroundColor = option.backgroundColor ?? .clear
    }
    
}

/// Table view controller that displays a set of possible options for a field
/// that the user can select from.
open class STFUFormOptionTableViewController: STFUFieldViewController {
    
    /// Custom table view cell implementation for an option table view
    /// controller.
    open class OptionTableViewCell: UITableViewCell {
        
        override open func setSelected(_ selected: Bool, animated: Bool) {
            accessoryType = selected ? .checkmark : .none
        }
        
    }
    
    // MARK: - Instance Properties
    
    /// Field of this option table view controller.
    override open var field: STFUField? {
        didSet {
            options = (field?.options ?? [:]).sorted { $0.0 < $1.0 }
        }
    }
    
    /// Options of this option table view controller
    open var options = [(String, STFUField)]()
    
    // MARK: - UI Components
    
    /// Table view of this form option table view controller.
    open lazy var tableView: UITableView = UITableView()
    
    // MARK: - Constructor Methods
    
    convenience public init(style: UITableView.Style) {
        self.init(nibName: nil, bundle: nil)
        tableView = UITableView(frame: .zero, style: style)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(OptionTableViewCell.self,
                           forCellReuseIdentifier: String(OptionTableViewCell.hash()))
    }
    
    // MARK: - UIViewController Methods
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.addConstrainedSubview(tableView)
    }
    
}

// MARK: - UITableViewDataSource Methods
extension STFUFormOptionTableViewController: UITableViewDataSource {
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let _cell =
            tableView.dequeueReusableCell(withIdentifier: String(OptionTableViewCell.hash()),
                                          for: indexPath)
        
        guard let cell = _cell as? OptionTableViewCell else { return _cell }
        
        let option = options[(indexPath as NSIndexPath).row].1
        
        cell.textLabel?.text = option.alternateTitle ?? option.title
        cell.textLabel?.font = option.font ?? cell.textLabel?.font
        cell.textLabel?.textColor = option.color ?? cell.textLabel?.textColor ?? .black
        cell.backgroundColor = option.backgroundColor ?? cell.backgroundColor ?? .white
        
        return cell
        
    }
    
}

// MARK: - UITableViewDelegate Methods
extension STFUFormOptionTableViewController: UITableViewDelegate {
    
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let option = options[indexPath.row].1
        cell.isSelected = (field?.value as? NSObject == option.value as? NSObject)
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        field?.value = options[indexPath.row].1.value
        tableView.reloadData()
    }
    
}
