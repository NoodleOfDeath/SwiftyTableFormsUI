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

/// Specifications for a form data source.
@objc
public protocol STFUFormDataSource: NSObjectProtocol {
    
    /// This method is called anytime a form is modified and needs to update
    /// the enabled/disabled state of the submit button of a form view
    /// controller. Returning `true` will allow the user to submit the form.
    /// Returning `false` will disable the submit button and prevent the form
    /// view controller from being submitted.
    ///
    /// - Parameters:
    ///     - form: that was updated.
    /// - Returns: specify `true` to allow the user to submit `form`.
    /// Specify `false` to disable the submission of `form`.
    func formCanSubmit(_ form: STFUForm) -> Bool
    
    /// When a form contains a set of options a use can select from, the data
    /// source will return a collection of fields that key.
    @objc optional
    func form(_ form: STFUForm, optionMapFor key: String) -> [String: Any]
    
    @objc optional
    func errorFieldForForm(_ form: STFUForm) -> String?
    
    @objc optional
    func errorMessageForForm(_ form: STFUForm) -> String?
    
}

/// Specifications for a form delegate.
@objc
public protocol STFUFormDelegate: NSObjectProtocol {
    
    @objc optional
    func formDidChange(_ form: STFUForm)
    
}

/// Simple data structure with a collection of fields
@objc
open class STFUForm: NSObject, Codable {
    
    /// Keys for encoding/decoding.
    public enum CodingKeys: String, CodingKey {
        case name
        case title
        case fieldMap = "fields"
        case sections
    }
    
    override open var description: String {
        return fields.description
    }
    
    /// Data source of this form.
    open weak var dataSource: STFUFormDataSource?
    
    /// Delegate of this form.
    open weak var delegate: STFUFormDelegate?
    
    /// Enumerated strings to use as notification identifiers.
    public static let didChangeNotification = Notification.Name("STFUForm.DidChange")
    
    /// Name of this form.
    public var name: String?
    
    /// Display title of this form.
    public var title: String?
    
    /// Data contained in this form as a dictionary.
    open var fields = [String: Any]() {
        didSet {
            NotificationCenter.default.post(
                name: STFUForm.didChangeNotification,
                object: self)
        }
    }
    
    /// Key-valye map of fields referenced by this form.
    open var fieldMap = [String: STFUField]() {
        didSet {
            for (_, field) in fieldMap {
                guard (field.type != .radio && field.type != .checkbox) || field.checked else { return }
                var value = field.value
                if let stringValue = value as? String {
                    value = stringValue.replacingOccurrences(of: field.units, with: "")
                }
                fields[field.name] = value
            }
        }
    }
    
    /// Raw field map of this form.
    open var rawFieldMap = [String: [String: Any]]() {
        didSet {
            var map = [String: STFUField]()
            rawFieldMap.forEach {
                let field = STFUField(id: $0.key, $0.value)
                field.form = self
                map[$0.key] = field
            }
            fieldMap = map
        }
    }
    
    /// Sections of this form.
    open var sections: [STFUSection] = [STFUSection]() {
        willSet {
            lastFieldCount = fieldCount
        }
        didSet {
            var n = 0
            for i in 0 ..< sections.count {
                n += fields(in: i).count
            }
            fieldCount = n
        }
    }
    
    /// Raw sections of this form.
    open var rawSections = [[String: Any]]() {
        didSet { sections = rawSections.map { STFUSection($0) } }
    }
    
    /// Previous value of `fieldCount`
    fileprivate var lastFieldCount = 0
    
    /// Stored number count of fields.
    fileprivate var fieldCount = 0
    
    /// Indicates if the number of visible fields has changed.
    open var sectionsNeedDisplay: Bool {
        var n = 0
        for i in 0 ..< sections.count {
            n += fields(in: i).count
        }
        let needDisplay = n != fieldCount
        fieldCount = n
        return needDisplay
    }
    
    ///
    open var canSubmit: Bool {
        return dataSource?.formCanSubmit(self) == true
    }
    
    // MARK: - Constructor Methods
    
    /// Constructs a new form from a given set of fields, sections, and an
    /// optional name.
    ///
    /// - Parameters:
    ///     - name: of the new form.
    ///     - title: of the new form.
    ///     - fieldMap: Surjective mapping between a set of _field names_
    /// and `Field` instances with which initialize this form.
    ///     - sections: of the new form.
    public init(name: String? = nil, title: String? = nil, fieldMap: [String: STFUField] = [:], sections: [STFUSection] = []) {
        self.name = name
        self.title = title
        super.init()
        self.fieldMap = fieldMap
        self.sections = sections
    }
    
    required public init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        fieldMap = try values.decode([String: STFUField].self, forKey: .fieldMap)
        sections = try values.decode([STFUSection].self, forKey: .sections)
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(fieldMap, forKey: .fieldMap)
        try container.encode(sections, forKey: .sections)
    }
    
    /// Constructs a new form from a given set of unparsed fields, sections,
    /// and an optional name.
    ///
    /// - Parameters:
    ///     - name: of the new form.
    ///     - title: of the new form.
    ///     - rawFieldMap: surjective mapping between a set of _field names_
    /// and dictionary objects from which initialize this form.
    ///     - rawSections: array of dictionary objects with which
    /// to initialize this form.
    public convenience init(name: String,
                            title: String? = nil,
                            rawFieldMap: [String: [String: Any]],
                            rawSections: [[String: Any]]) {
        self.init(name: name, title: title)
        self.rawFieldMap = rawFieldMap
        self.rawSections = rawSections
    }
    
    /// Constructs a new form from a given bundle.
    ///
    /// - Parameters:
    ///     - path: of a form bundle to initialize from.
    /// - Note: The info dictionary of `bundle` must contain a dictionary for
    /// the key `Key.Fields`, and an array of dictionaries for the key
    /// `Key.Sections`, for this constructor to pass a non-`nil` value.
    ///
    /// The _fields_ dictionary should be a surjective mapping between a set of
    /// _field names_ and a set of dictionary objects from which to initialize
    /// `Field` instances (See `Field` to see what each entry of
    /// the _fields_ dictionary should contain.
    ///
    /// The _sections_ array should contain dictionary objects from which to
    /// initialize `Section` instances (See `Section` to see what
    /// each entry of the _sections_ dictionary should contain).
    public convenience init?(path: String) {
        guard let bundle = Bundle(path: path) else { return nil }
        guard let name = bundle.infoDictionary?[CodingKeys.name] as? String else { return nil }
        let title = bundle.infoDictionary?[CodingKeys.title] as? String
        let rawFieldMap = bundle.infoDictionary?[CodingKeys.fieldMap] as? [String: [String: Any]] ?? [:]
        let rawSections = bundle.infoDictionary?[CodingKeys.sections] as? [[String: Any]] ?? []
        self.init(name: name, title: title, rawFieldMap: rawFieldMap, rawSections: rawSections)
    }
    
    // MARK: - Instance Methods
    
    /// Subscript method for getting and setting field values.
    open subscript (key: String) -> Any? {
        get { return fields[key] }
        set {
            fieldMap.values.filter { $0.name == key }.forEach {
                guard ($0.type != .radio && $0.type != .checkbox) else { return }
                $0.value = newValue
            }
        }
    }
    
    /// Returns an array of form fields for a given section index.
    ///
    /// - Parameters:
    ///     - section: to retrieve form fields from.
    /// - Returns: An array of form fields for the given `section` index.
    open func fields(in section: Int) -> [STFUField] {
        let fields = sections[section].fields
        var rows = [STFUField]()
        for id in fields {
            if id == STFUFieldType.separator.rawValue || id == "" {
                rows.append(.separator)
                continue
            }
            guard let field = fieldMap[id] else { continue }
            if !field.enabled && field.hideWhenDisabled { continue }
            rows.append(field)
        }
        return rows
    }
    
    /// Adds a field to this form.
    ///
    /// - Parameters:
    ///     - field: to add to this form.
    open func add(_ fields: STFUField...) {
        for field in fields {
            field.form = self
            fieldMap[field.id] = field
            field.evaluateDependencies()
        }
    }
    
    /// Adds a section to this form.
    ///
    /// - Parameters:
    ///     - section: to add to this form.
    open func add(_ sections: STFUSection...) {
        self.sections.append(contentsOf: sections)
    }
    
    /// Returns the options for an option map key.
    ///
    /// - Parameters:
    ///     - key: of the option map to get.
    open func optionMap(for key: String) -> [String: Any] {
        return dataSource?.form?(self, optionMapFor: key) ?? [:]
    }
    
    ///
    open func field(_ field: STFUField, didChangeEnabledState enabled: Bool) {
        fields[field.name] = enabled ? field.value : nil
    }
    
    /// Called when a form field value is changed to update the raw data
    /// of this form.
    ///
    /// - Parameters:
    ///     - field: whose value was changed.
    ///     - oldValue: of `field`.
    open func field(_ field: STFUField, didChangeValueFrom oldValue: Any?) {
        guard field.type != .radio || field.checked else { return }
        var value = field.value
        if field.type == .stepper {
            if let stringValue = value as? String {
                let stringValue = stringValue.replacingOccurrences(of: " ", with: "")
                value = stringValue.replacingOccurrences(of: field.units, with: "")
            }
        }
        fields[field.name] = value
    }
    
}



