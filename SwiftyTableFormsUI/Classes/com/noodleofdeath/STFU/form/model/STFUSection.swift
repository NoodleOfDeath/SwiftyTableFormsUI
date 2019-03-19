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

/// Simple structure with a header, footer, set of fields names, and hidden
/// flag.
public struct STFUSection: Codable {
    
    public enum CodingKeys: String, CodingKey {
        case header
        case footer
        case fields
        case hidden
    }
    
    /// Title to display as the header for this section.
    public let header: String
    
    /// String to display at the footer of this section.
    public let footer: String
    
    /// Collection of the unique field names in this section.
    public let fields: [String]
    
    /// Indicates whether to hide or display this section. Default value is
    /// `false`; i.e. display the section.
    public let hidden: Bool
    
    /// Constructs a new form section with a given header, footer, and set of
    /// field names.
    public init(header: String = "", footer: String = "", fields: [String], hidden: Bool = false) {
        self.header = header
        self.footer = footer
        self.fields = fields
        self.hidden = hidden
    }
    
    /// Constructs a new form section with a given header, footer, and set of
    /// field names.
    public init(header: String = "", footer: String = "", fields: [STFUField], hidden: Bool = false) {
        self.header = header
        self.footer = footer
        self.fields = fields.map { $0.id }
        self.hidden = hidden
    }
    
    /// Constructs a new form section with a given header, footer, and set of
    /// field names.
    public init(header: String = "", footer: String = "", fields: String..., hidden: Bool = false) {
        self.header = header
        self.footer = footer
        self.fields = fields
        self.hidden = hidden
    }
    
    /// Constructs a new form section with a given header, footer, and set of
    /// field names.
    public init(header: String = "", footer: String = "", fields: STFUField..., hidden: Bool = false) {
        self.header = header
        self.footer = footer
        self.fields = fields.map { $0.id }
        self.hidden = hidden
    }
    
    /// Constructs a new form section from a specified dictionary
    ///
    /// - Parameters:
    ///     - dict: to initialize this form section with.
    public init(_ keyValues: [String: Any]?) {
        header = keyValues?[CodingKeys.header] as? String ?? ""
        footer = keyValues?[CodingKeys.footer] as? String ?? ""
        fields = keyValues?[CodingKeys.fields] as? [String] ?? []
        hidden = keyValues?[CodingKeys.hidden] as? Bool ?? false
    }
    
}

