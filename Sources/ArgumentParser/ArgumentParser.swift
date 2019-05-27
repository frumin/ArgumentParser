//
//  ArgumentParser.swift
//  ArgumentParser
//
//  Created by Tom Zaworowski on 5/21/19.
//

import Foundation

public enum ParsingError: Error {
    case missingParameterValue(Parameter)
    case missingParameter(Parameter)
    case missingOption
    case missingVerb
}

public enum LookupError: Error {
    case parameterNotResolved
}

public protocol Parsable {
    typealias ResolvedParameter = (parameter: Parameter, value: String?)
    typealias Callback = (_ parameters: [ResolvedParameter]?) -> Void
    var name: String { get }
    var callback: Callback? { get }
    func test(arguments: [String]) throws -> Bool
    func evaluate(arguments: [String]) throws
}

public extension Parsable {
    func evaluate(arguments: [String]) throws {
        if try test(arguments: arguments) {
            callback?(nil)
        }
    }
}

public protocol Parser {
    func parse(_ parsables: [Parsable]) throws
}

public struct Option: Parsable {
    public let name: String
    public let isRequired: Bool?
    public let callback: Callback?
    
    public init(name: String, isRequired: Bool = false, callback: Callback?) {
        self.name = name
        self.isRequired = isRequired
        self.callback = callback
    }
    
    public func test(arguments: [String]) throws -> Bool {
        return arguments.contains(name) || isRequired == false
    }
}

public struct Verb: Parsable {
    public let name: String
    public let parameters: [Parameter]?
    public let callback: Callback?
    
    public init(name: String, parameters: [Parameter]? = nil, callback: Callback?) {
        self.name = name
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

public struct Group: Parsable {
    enum ParsingError: Error {
        case multipleVerbs
    }
    
    public var name: String
    public var verbs: [Verb]
    public var callback: Callback?
    
    public init(name: String, verbs: [Verb], callback: Callback?) {
        self.name = name
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

extension CommandLine: Parser {
    public static func parse(_ parsables: [Parsable]) throws {
        for parsable in parsables {
            try parsable.evaluate(arguments: Array(arguments.dropFirst()))
        }
    }
    
    public func parse(_ parsables: [Parsable]) throws {
        try CommandLine.parse(parsables)
    }
}

public extension Sequence where Iterator.Element == Parsable.ResolvedParameter {
    var allParamaters: [Parameter] {
        return self.compactMap {
            return $0.parameter
        }
    }
    
    func value(for parameterName: String) throws -> String? {
        guard let resolvedParamater = first(where: { (element) -> Bool in
            element.parameter.name == parameterName
        }) else {
            throw LookupError.parameterNotResolved
        }
        return resolvedParamater.value
    }
}
