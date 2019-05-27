//
//  Extensions.swift
//  ArgumentParser
//
//  Created by Tom Zaworowski on 5/27/19.
//

import Foundation

public extension Parsable {
    func evaluate(arguments: [String]) throws {
        if try test(arguments: arguments) {
            callback?(nil)
        }
    }
}

extension CommandLine: Parser {
    public static func parse(_ parsables: [Parsable]) throws {
        let sanitizedArguments = Array(arguments.dropFirst())
        if parsables.containsRequiredParsable == false && sanitizedArguments.isEmpty {
            parsables.printHelp()
            return
        }
        for parsable in parsables.defaultParsables {
            try parsable.evaluate(arguments: sanitizedArguments)
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

extension Collection where Iterator.Element == Parameter {
    var containsRequiredParameter: Bool {
        return contains(where: { (element) -> Bool in
            return element.isRequired
        })
    }
}

extension RangeReplaceableCollection where Iterator.Element == Parsable {
    var defaultParsables: Self {
        var parsables = self
        let help = Option(name: "help", description: "show help") { (_) in self.printHelp() }
        if self.contains(where: { (parsable) -> Bool in parsable.name == help.name }) == false {
            parsables.append(help)
        }
        return parsables
    }
    
    var containsRequiredParsable: Bool {
        return contains { (element) -> Bool in
            if let element = element as? Group {
                return element.verbs.contains(where: { (verb) -> Bool in
                    return verb.parameters?.containsRequiredParameter ?? false
                })
            }
            if let element = element as? Verb {
                return element.parameters?.containsRequiredParameter ?? false
            }
            if let element = element as? Option {
                return element.isRequired ?? false
            }
            return false
        }
    }
    
    func printHelp() {
        var help = "Usage:\n\n"
        for parsable in self {
            help += "\(parsable.name): \(parsable.description)\n"
        }
        print(help)
    }
}
