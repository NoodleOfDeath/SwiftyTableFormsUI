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

import Foundation
import SwiftyTextStyles

extension UIKeyboardType: Codable {}
extension UITextAutocapitalizationType: Codable {}
extension UITextAutocorrectionType: Codable {}

/// Enumerated type specifying different types of fields that can appear
/// in a form.
public enum STFUFieldType: String, Codable {
    case button
    case color
    case hidden
    case picker
    case radio
    case separator
    case slider
    case stepper
    case text
    case title
    case checkbox
    case url
}

/// Data structure with a type, name, value, and other miscellaneous metadata.
@objc
open class STFUField: NSObject, Codable {
    
    public typealias This = STFUField
    
    public enum CodingKeys: String, CodingKey {
        
        case id
        case name
        
        case type
        
        case value
        case defaultValue
        case checked
        
        case dependencies
        
        case image
        case title
        case alternateTitle
        
        case info
        case placeholder
        
        case font
        case color
        case backgroundColor
        
        case optionMapName
        case options
        
        case min
        case max
        case stepSize
        case precision
        case units
        
        case isSecure
        case keyboardType
        
        case autocapitalizationType
        case autocorrectionType
        
        case hideWhenDisabled
        
    }
    
    /// Notification name for the notification posted each time the value of
    /// this field changes.
    public static var didChangeNotification = Notification.Name("STFUField.DidChange")
    
    /// Notification name for the notification posted each time this field
    /// changes its enabled state.
    public static var didChangeEnabledStateNotification = Notification.Name("STFUField.DidChangeEnabledState")
    
    /// Creates a new field instance that is a separator.
    open class var separator: This { return This(type: .separator) }
    
    /// STFUForm object to which this field belongs to.
    open weak var form: STFUForm? {
        didSet { evaluateDependencies() }
    }
    
    // MARK: - Configuration Properties
    
    /// Unique id of this field.
    public let id: String
    
    /// Unique name of this field.
    public let name: String
    
    /// Type of this field. Default value is `.hidden`.
    open var type: STFUFieldType = .hidden
    
    /// Value of this field.
    open var value: Any? {
        didSet {
            form?.field(self, didChangeValueFrom: oldValue)
            NotificationCenter.default.post(
                name: STFUField.didChangeNotification,
                object: self)
        }
    }
    
    /// Default value for this field.
    open var defaultValue: Any?
    
    /// Boolean flag indicating if this field is checked or not.
    open var checked: Bool = false {
        didSet{
            form?.field(self, didChangeValueFrom: oldValue)
            NotificationCenter.default.post(name: STFUField.didChangeNotification,
                                            object: self)
        }
    }
    
    /// Fields whose state(s)/value are dependent on the value of this field.
    open var dependencies: [STFUField]?
    
    /// Title text to display beside this field in the UI.
    open var title: String?
    
    /// Text to display
    open var alternateTitle: String?
    
    /// Image to display for this field.
    open var image: UIImage?
    
    /// Text to diplay below this field in the UI.
    open var info: String?
    
    /// Text to display as the placeholder of this field, if it is a `text`
    /// field.
    open var placeholder: String?
    
    /// Font to use when displaying the `alternateTitle`.
    open var font: UIFont?
    
    /// Font color to use when displaying the `alternateTitle`.
    open var color: UIColor? = .black
    
    /// Background color to use when displaying the `alternateTitle`.
    open var backgroundColor: UIColor? = .white
    
    /// Sets the option set name of this field and then loads its options.
    open var optionMapName: String? {
        didSet {
            load(options: [:])
            guard
                let optionMapName = optionMapName,
                let options = form?.optionMap(for: optionMapName) else { return }
            load(options: options)
        }
    }
    
    /// Collection of possible values for this field.
    open var options = [String: STFUField]()

    /// Minimum value allowed for this field of it is a `.stepper` field.
    open var min: Double = .leastNormalMagnitude
    
    /// Maximum value allowed for this field of it is a `.stepper` field.
    open var max: Double = .greatestFiniteMagnitude
    
    /// Step size to use when incrementinv/decrementing the value of
    /// this field. Default value is `1.0`.
    open var stepSize: Double = 1.0
    
    /// Number of decimal points to use when displaying the value of this
    /// field. Default value is `0`.
    open var precision: UInt = 0
    
    /// Units used by this field.
    open var units: String = ""
    
    /// Indicates whether, or not, this field is a password text field.
    open var isSecure: Bool = false
    
    /// Keyboard type that should be used when editing this field.
    open var keyboardType: UIKeyboardType = .default
    
    /// Autocapitalization type of this field. Default value is `.none`.
    open var autocapitalizationType: UITextAutocapitalizationType = .none
    
    /// Auto correction type of this field. Default value is `.no`.
    open var autocorrectionType: UITextAutocorrectionType = .no
    
    /// If set to `true`, this field will be hidden from view altogether
    /// if disabled. Default is `false`.
    open var hideWhenDisabled: Bool = false
    
    // MARK: - Runtime Properties
    
    /// Indicates whether, or not, this field is loading.
    open var loading: Bool = false
    
    /// Indicates whether, or not, this field is enabled. Default value
    /// is `true`.
    open var enabled: Bool = true {
        didSet {
            if oldValue != enabled {
                form?.field(self, didChangeEnabledState: enabled)
                NotificationCenter.default.post(
                    name: STFUField.didChangeEnabledStateNotification,
                    object: self)
            }
        }
    }
    
    // MARK: - Constructor Methods
    
    /// Contructs a new form field instance with an initial id, name, type,
    /// title, and value.
    ///
    /// - Parameters:
    ///     - id: of the new field.
    ///     - name: of the new field.
    ///     - type: of the new field.
    ///     - title: of the new field.
    ///     - image: of the new field.
    ///     - value: of the new field.
    ///     - keyValues: of the new field.
    public init(id: String? = nil,
                name: String = STFUFieldType.separator.rawValue,
                type: STFUFieldType = .separator,
                title: String? = nil,
                image: UIImage? = nil,
                value: Any? = nil,
                _ keyValues: [String: Any] = [:]) {
        self.id = id ?? name
        self.name = name
        super.init()
        self.type = type
        self.title = title
        self.image = image
        self.value = value
        load(from: keyValues)
    }
    
    /// Contructs a new form field instance with an initial id, name, type,
    /// title, and value.
    ///
    /// - Parameters:
    ///     - id: of the new field.
    ///     - name: of the new field.
    ///     - type: of the new field.
    ///     - title: of the new field.
    ///     - image: of the new field.
    ///     - value: of the new field.
    ///     - keyValues: of the new field.
    public init(id: String? = nil,
                name: String = STFUFieldType.separator.rawValue,
                type: STFUFieldType = .separator,
                title: String? = nil,
                image: UIImage? = nil,
                value: Any? = nil,
                _ keyValues: [CodingKeys: Any]) {
        self.id = id ?? name
        self.name = name
        super.init()
        self.type = type
        self.title = title
        self.image = image
        self.value = value
        load(from: keyValues)
    }
    
    /// Constructs a new form field from a given dictionary.
    ///
    /// - Parameters:
    ///     - dict: to load from.
    required public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        
        type = try values.decode(STFUFieldType.self, forKey: .type)
        
        if let decodedValue = try values.decodeIfPresent(Bool.self, forKey: .value) {
            value = decodedValue
        } else if let decodedValue = try values.decodeIfPresent(Data.self, forKey: .value) {
            value = decodedValue
        } else if let decodedValue = try values.decodeIfPresent(Double.self, forKey: .value) {
            value = decodedValue
        } else if let decodedValue = try values.decodeIfPresent(String.self, forKey: .value) {
            value = decodedValue
        } else if let decodedValue = try values.decodeIfPresent(URL.self, forKey: .value) {
            value = decodedValue
        }
        
        if let decodedValue = try values.decodeIfPresent(Bool.self, forKey: .defaultValue) {
            defaultValue = decodedValue
        } else if let decodedValue = try values.decodeIfPresent(Data.self, forKey: .defaultValue) {
            defaultValue = decodedValue
        } else if let decodedValue = try values.decodeIfPresent(Double.self, forKey: .defaultValue) {
            defaultValue = decodedValue
        } else if let decodedValue = try values.decodeIfPresent(String.self, forKey: .defaultValue) {
            defaultValue = decodedValue
        } else if let decodedValue = try values.decodeIfPresent(URL.self, forKey: .defaultValue) {
            defaultValue = decodedValue
        }
        
        checked = try values.decode(Bool.self, forKey: .checked)
        
        dependencies = try values.decodeIfPresent([STFUField].self, forKey: .dependencies)
        
        title = try values.decodeIfPresent(String.self, forKey: .title)
        alternateTitle = try values.decodeIfPresent(String.self, forKey: .alternateTitle)
        
        if let data = try values.decodeIfPresent(Data.self, forKey: .image) {
            image ?= UIImage(data: data)
        }
        
        info = try values.decodeIfPresent(String.self, forKey: .info)
        placeholder = try values.decodeIfPresent(String.self, forKey: .placeholder)
        
        if let data = try values.decodeIfPresent(Data.self, forKey: .font) {
            font = UIFont.decode(from: try JSONSerialization.jsonObject(with: data, options: []))
        }
        
        if let data = try values.decodeIfPresent(Data.self, forKey: .color) {
            color = UIColor.decode(from: try JSONSerialization.jsonObject(with: data, options: []))
        }
        
        if let data = try values.decodeIfPresent(Data.self, forKey: .backgroundColor) {
            backgroundColor = UIColor.decode(from: try JSONSerialization.jsonObject(with: data, options: []))
        }
        
        optionMapName = try values.decodeIfPresent(String.self, forKey: .optionMapName)
        
        options ?= try values.decodeIfPresent([String: STFUField].self, forKey: .options)
        
        min = try values.decode(Double.self, forKey: .min)
        max = try values.decode(Double.self, forKey: .max)
        stepSize = try values.decode(Double.self, forKey: .stepSize)
        precision = try values.decode(UInt.self, forKey: .precision)
        units = try values.decode(String.self, forKey: .units)
        
        isSecure = try values.decode(Bool.self, forKey: .isSecure)
        keyboardType = try values.decode(UIKeyboardType.self, forKey: .keyboardType)
        
        autocapitalizationType = try values.decode(UITextAutocapitalizationType.self, forKey: .autocapitalizationType)
        autocorrectionType = try values.decode(UITextAutocorrectionType.self, forKey: .autocorrectionType)
        
        hideWhenDisabled = try values.decode(Bool.self, forKey: .hideWhenDisabled)

    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        if let value = value as? Bool {
            try container.encode(value, forKey: .value)
        } else if let value = value as? Data {
            try container.encode(value, forKey: .value)
        } else if let value = value as? Double {
            try container.encode(value, forKey: .value)
        } else if let value = value as? String {
            try container.encode(value, forKey: .value)
        } else if let value = value as? URL {
            try container.encode(value, forKey: .value)
        }
        if let defaultValue = defaultValue as? Bool {
            try container.encode(defaultValue, forKey: .defaultValue)
        } else if let defaultValue = defaultValue as? Data {
            try container.encode(defaultValue, forKey: .defaultValue)
        } else if let defaultValue = defaultValue as? Double {
            try container.encode(defaultValue, forKey: .defaultValue)
        } else if let defaultValue = defaultValue as? String {
            try container.encode(defaultValue, forKey: .defaultValue)
        } else if let defaultValue = defaultValue as? URL {
            try container.encode(defaultValue, forKey: .defaultValue)
        }
        try container.encode(checked, forKey: .checked)
        try container.encodeIfPresent(dependencies, forKey: .dependencies)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(alternateTitle, forKey: .alternateTitle)
        if let image = image {
            try container.encodeIfPresent(UIImagePNGRepresentation(image), forKey: .image)
        }
        try container.encodeIfPresent(info, forKey: .info)
        try container.encodeIfPresent(placeholder, forKey: .placeholder)
        if let font = font {
            try container.encode(try JSONSerialization.data(withJSONObject: font.jsonObject, options: []), forKey: .font)
        }
        if let color = color {
            try container.encode(try JSONSerialization.data(withJSONObject: color.jsonObject, options: []), forKey: .color)
        }
        if let backgroundColor = backgroundColor {
            try container.encode(try JSONSerialization.data(withJSONObject: backgroundColor.jsonObject, options: []), forKey: .backgroundColor)
        }
        try container.encodeIfPresent(optionMapName, forKey: .optionMapName)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encode(min, forKey: .min)
        try container.encode(max, forKey: .max)
        try container.encode(stepSize, forKey: .stepSize)
        try container.encode(precision, forKey: .precision)
        try container.encode(units, forKey: .units)
        try container.encode(isSecure, forKey: .isSecure)
        try container.encode(keyboardType, forKey: .keyboardType)
        try container.encode(autocapitalizationType, forKey: .autocapitalizationType)
        try container.encode(autocorrectionType, forKey: .autocorrectionType)
        try container.encode(hideWhenDisabled, forKey: .hideWhenDisabled)
    }
    
}

// MARK: - Instance Methods
extension STFUField {
    
    /// Constructs a new form field from a dictionary of key-values.
    ///
    /// - Parameters:
    ///     - keyValues: to load from.
    public func load(from keyValues: [String: Any]?) {
        
        guard let keyValues = keyValues else { return }
        
        if let dependencies = keyValues[CodingKeys.dependencies] as? [[String : Any]] {
            load(dependencies: dependencies)
        } else if let dependencies = keyValues[CodingKeys.dependencies] as? [STFUField] {
            self.dependencies = dependencies
        }
        
        value ?= keyValues[CodingKeys.value]
        defaultValue ?= keyValues[CodingKeys.defaultValue]
        checked ?= keyValues[CodingKeys.checked] as? Bool
        
        title ?= keyValues[CodingKeys.title] as? String
        alternateTitle ?= keyValues[CodingKeys.alternateTitle] as? String
        image ?= keyValues[CodingKeys.image] as? UIImage
        
        info ?= keyValues[CodingKeys.info] as? String
        placeholder ?= keyValues[CodingKeys.placeholder] as? String
        
        font ?= UIFont.decode(from: keyValues[CodingKeys.font])
        color ?= UIColor.decode(from: keyValues[CodingKeys.color])
        backgroundColor ?= UIColor.decode(from: keyValues[CodingKeys.backgroundColor])
        
        if value == nil { value = defaultValue }
        
        var options = keyValues[CodingKeys.optionMapName] as? [String: Any]
        if options == nil, let optionMapName = keyValues[CodingKeys.optionMapName] as? String {
            options ?= form?.optionMap(for: optionMapName)
        }
        load(options: options)
        
        min ?= keyValues[CodingKeys.min] as? Double
        max ?= keyValues[CodingKeys.max] as? Double
        stepSize ?= keyValues[CodingKeys.stepSize] as? Double
        
        precision ?= keyValues[CodingKeys.precision] as? UInt
        units ?= keyValues[CodingKeys.units] as? String
        
        hideWhenDisabled ?= keyValues[CodingKeys.hideWhenDisabled] as? Bool
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(formDidChange(_:)),
            name: STFUForm.didChangeNotification,
            object: form)
        
    }
    
    /// Constructs a new form field from a dictionary of key-values.
    ///
    /// - Parameters:
    ///     - keyValues: to load from.
    public func load(from keyValues: [CodingKeys: Any]?) {
        
        guard let keyValues = keyValues else { return }
        
        if let dependencies = keyValues[.dependencies] as? [[CodingKeys : Any]] {
            load(dependencies: dependencies)
        } else if let dependencies = keyValues[.dependencies] as? [STFUField] {
            self.dependencies = dependencies
        }
        
        value ?= keyValues[.value]
        defaultValue ?= keyValues[.defaultValue]
        checked ?= keyValues[.checked] as? Bool
        
        title ?= keyValues[.title] as? String
        alternateTitle ?= keyValues[.alternateTitle] as? String
        image ?= keyValues[.image] as? UIImage
        
        info ?= keyValues[.info] as? String
        placeholder ?= keyValues[.placeholder] as? String
        
        font ?= UIFont.decode(from: keyValues[.font])
        color ?= UIColor.decode(from: keyValues[.color])
        backgroundColor ?= UIColor.decode(from: keyValues[.backgroundColor])
        
        if value == nil { value = defaultValue }
        
        var options = keyValues[.optionMapName] as? [String: Any]
        if options == nil, let optionMapName = keyValues[.optionMapName] as? String {
            options ?= form?.optionMap(for: optionMapName)
        }
        load(options: options)
        
        min ?= keyValues[.min] as? Double
        max ?= keyValues[.max] as? Double
        stepSize ?= keyValues[.stepSize] as? Double
        
        precision ?= keyValues[.precision] as? UInt
        units ?= keyValues[.units] as? String
        
        hideWhenDisabled ?= keyValues[.hideWhenDisabled] as? Bool
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(formDidChange(_:)),
            name: STFUForm.didChangeNotification,
            object: form)
        
    }
    
    /// Evaluates the dependencies of this field checking to see if the
    /// desired values are all true, then disables or enables itself
    /// accordingly.
    open func evaluateDependencies() {
        guard let dependencies = dependencies
            else { self.enabled = true; return }
        var enabled = true
        for dependency in dependencies {
            guard let desiredValue = dependency.value as? NSObject else { continue }
            let currentValue = form?[dependency.name] as? NSObject
            if currentValue != desiredValue {
                enabled = false
            }
        }
        self.enabled = enabled
    }
    
    /// Loads dependency fields.
    ///
    /// - Parameters:
    ///     - dependencies: dictionary of unparsed form fields
    /// specifying dependency requirements for this field to be enabled.
    fileprivate func load(dependencies: [[String: Any]]?) {
        var _dependencies = [STFUField]()
        dependencies?.forEach {
            _dependencies.append(STFUField($0))
        }
        self.dependencies = _dependencies
    }
    
    /// Loads dependency fields.
    ///
    /// - Parameters:
    ///     - dependencies: dictionary of unparsed form fields
    /// specifying dependency requirements for this field to be enabled.
    fileprivate func load(dependencies: [[CodingKeys: Any]]?) {
        var _dependencies = [STFUField]()
        dependencies?.forEach {
            _dependencies.append(STFUField($0))
        }
        self.dependencies = _dependencies
    }
    
    /// Parses options from a given a dictionaries.
    ///
    /// - Parameters:
    ///     - options: dictionary containing form field options.
    fileprivate func load(options: [String: Any]?) {
        guard let options = options as? [String: [CodingKeys: Any]] else { return }
        self.options = [String: STFUField]()
        for (key, dict) in options {
            self.options[key] = STFUField(dict)
        }
    }
    
}

// MARK: - Event Handler Methods
extension STFUField {
    
    /// Called when `form` is changed.
    ///
    /// - Parameters:
    ///     - notification: Notification object containing information
    /// about the triggered event.
    @objc
    fileprivate func formDidChange(_ notification: Notification) {
        NotificationCenter.default.removeObserver(
            self,
            name: STFUForm.didChangeNotification,
            object: form)
        evaluateDependencies()
        guard let _ = dependencies else { return }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(formDidChange(_:)),
            name: STFUForm.didChangeNotification,
            object: form)
    }

}

