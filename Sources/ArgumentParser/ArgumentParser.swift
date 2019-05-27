//
//  ArgumentParser.swift
//  ArgumentParser
//
//  Created by Tom Zaworowski on 5/21/19.
//

import Foundation

/// Error thrown during parsing
///
/// - missingParameterValue: Required parameter is missing a required value
/// - missingParameter: Required parameter is missing
/// - missingOption: Required option is missing
/// - missingVerb: Missing at least one verb
public enum ParsingError: Error {
    case missingParameterValue(Parameter)
    case missingParameter(Parameter)
    case missingOption
    case missingVerb
}

public enum LookupError: Error {
    case parameterNotResolved
}

/// Defines a structure that can be parsed with argument array
public protocol Parsable {
    
    /// Parsed parameter with optional value
    typealias ResolvedParameter = (parameter: Parameter, value: String?)
    
    /// Closure containing resolved parameters
    typealias Callback = (_ parameters: [ResolvedParameter]?) -> Void
    
    /// String value that will be matched against parameters array
    var name: String { get }
    
    /// Describes usage
    var description: String { get }
    
    /// Called when Parsable successfully evaluates
    var callback: Callback? { get }
    
    /// Test arguments for Parsable presence
    ///
    /// - Parameter arguments: array of command line arguments
    /// - Returns: `true` if arguments contain the element, otherwise `false`
    /// - Throws: error when element is required and missing
    func test(arguments: [String]) throws -> Bool
    
    /// Evalutes arguments and calls completion on found Parsable elements
    ///
    /// - Parameter arguments: array of command line arguments
    /// - Throws: error when element is required and missing
    func evaluate(arguments: [String]) throws
}

/// Defines an argument parser
public protocol Parser {
    func parse(_ parsables: [Parsable]) throws
}

/// A parsable that only matches a name
public struct Option: Parsable {
    public let name: String
    public let description: String
    public let isRequired: Bool?
    public let callback: Callback?
    
    public init(name: String, description: String, isRequired: Bool = false, callback: Callback?) {
        self.name = name
        self.description = description
        self.isRequired = isRequired
        self.callback = callback
    }
    
    public func test(arguments: [String]) throws -> Bool {
        if arguments.contains(name) == false {
            if isRequired ?? false {
                throw ParsingError.missingOption
            }
            return false
        }
        return true
    }
}

/// A parsable that matches a name and optional parameters
public struct Verb: Parsable {
    public let name: String
    public var description: String
    public let parameters: [Parameter]?
    public let callback: Callback?
    
    public init(name: String, description: String, parameters: [Parameter]? = nil, callback: Callback?) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.callback = callback
    }
    
    public func test(arguments: [String]) throws -> Bool {
        var parameters = [ResolvedParameter]()
        return try test(arguments: arguments, resolvedParameters: &parameters)
    }
    
    public func evaluate(arguments: [String]) throws {
        var parameters = [ResolvedParameter]()
        if try test(arguments: arguments, resolvedParameters: &parameters) {
            callback?(parameters)
        }
    }
    
    private func test(arguments: [String], resolvedParameters: inout [ResolvedParameter]) throws -> Bool {
        guard arguments.first == name else {
            return false
        }
        guard let parameters = parameters else {
            return true
        }
        let arguments = Array(arguments.dropFirst())
        for parameter in parameters {
            guard let index = arguments.firstIndex(of: parameter.name) else {
                if parameter.isRequired {
                    throw ParsingError.missingParameter(parameter)
                }
                resolvedParameters.append((parameter, nil))
                continue
            }
            let nextIndex = index.advanced(by: 1)
            guard arguments.count > nextIndex else {
                if parameter.valueRequired {
                    throw ParsingError.missingParameterValue(parameter)
                }
                resolvedParameters.append((parameter, nil))
                continue
            }
            let nextArgument = arguments[nextIndex]
            guard parameters.contains(where: { $0.name == nextArgument }) == false else {
                if parameter.valueRequired {
                    throw ParsingError.missingParameterValue(parameter)
                }
                resolvedParameters.append((parameter, nil))
                continue
            }
            resolvedParameters.append((parameter, nextArgument))
        }
        return true
    }
}

/// A collection of verbs, at least one must be present in arguments array
public struct Group: Parsable {
    enum ParsingError: Error {
        case multipleVerbs
    }
    
    public var name: String
    public var description: String
    public var verbs: [Verb]
    public var callback: Callback?
    
    public init(name: String, description: String, verbs: [Verb], callback: Callback?) {
        self.name = name
        self.description = description
        self.verbs = verbs
        self.callback = callback
    }
    
    public func test(arguments: [String]) throws -> Bool {
        var lastPass = false
        for verb in verbs {
            let pass = arguments.contains(verb.name)
            if pass {
                guard lastPass == false else {
                    throw ParsingError.multipleVerbs
                }
                lastPass = pass
            }
        }
        return lastPass
    }
    
    public func evaluate(arguments: [String]) throws {
        if try test(arguments: arguments) {
            for verb in verbs {
                try verb.evaluate(arguments: arguments)
            }
            callback?(nil)
        }
    }
    
}

/// An optional match for some parsables
public struct Parameter: Hashable {
    public let name: String
    public let isRequired: Bool
    public let valueRequired: Bool
    
    public init(name: String, isRequired: Bool = false, valueRequired: Bool = false) {
        self.name = name
        self.isRequired = isRequired
        self.valueRequired = valueRequired
    }
}
