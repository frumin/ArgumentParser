import XCTest
@testable import ArgumentParser

final class ArgumentParserTests: XCTestCase {
    
    override func setUp() {
        CommandLine.arguments = [String(describing: self)]
    }
    
    func testSingleOption() {
        let testOptionName = "-test"
        CommandLine.arguments.append(testOptionName)
        
        let expectation = XCTestExpectation(description: "Verify callback")
        let option = Option(name: testOptionName, isRequired: true) { (_) in
            expectation.fulfill()
        }
        try! CommandLine.parse([option])
        wait(for: [expectation], timeout: 1)
    }
    
    func testSingleVerb() {
        let testVerbName = "test"
        CommandLine.arguments.append(testVerbName)
        
        let expectation = XCTestExpectation(description: "Verify callback")
        let verb = Verb(name: testVerbName, parameters: nil) { (parameters) in
            expectation.fulfill()
        }
        try! CommandLine.parse([verb])
        wait(for: [expectation], timeout: 1)
    }
    
    func testSingleVerbWithParameter() {
        let testVerbName = "test"
        let testParamName = "--source"
        CommandLine.arguments.append(contentsOf: [testVerbName, testParamName])
        
        let expectation = XCTestExpectation(description: "Verify callback")
        let parameter = Parameter(name: testParamName, isRequired: true, valueRequired: false)
        let verb = Verb(name: testVerbName, parameters: [parameter]) { (parameters) in
            XCTAssert(parameters?.count == 1, "Must have one parameter")
            XCTAssert(parameters?.first?.parameter.name == testParamName, "Parameter must match")
            expectation.fulfill()
        }
        try! CommandLine.parse([verb])
        wait(for: [expectation], timeout: 1)
    }
    
    func testSingleVerbWithParameterValue() {
        let testVerbName = "test"
        let testParamName = "--source"
        let testParamValue = "foo"
        CommandLine.arguments.append(contentsOf: [testVerbName, testParamName, testParamValue])
        
        let expectation = XCTestExpectation(description: "Verify callback")
        let parameter = Parameter(name: testParamName, isRequired: true, valueRequired: true)
        let verb = Verb(name: testVerbName, parameters: [parameter]) { (parameters) in
            XCTAssert(parameters?.count == 1, "Must have one parameter")
            XCTAssert(parameters?.first?.parameter.name == testParamName, "Parameter must match")
            XCTAssert(parameters?.first?.value == testParamValue, "Values must match")
            expectation.fulfill()
        }
        try! CommandLine.parse([verb])
        wait(for: [expectation], timeout: 1)
    }
    
    func testSingleVerbWithMultipleParametersValue() {
        let testVerbName = "test"
        let testParamName = "--source"
        let testParamValue = "foo"
        let secondParamName = "--output"
        CommandLine.arguments.append(contentsOf: [testVerbName, testParamName, testParamValue])
        
        let expectation = XCTestExpectation(description: "Verify callback")
        let parameter = Parameter(name: testParamName, isRequired: true, valueRequired: true)
        let secondParameter = Parameter(name: secondParamName, isRequired: false, valueRequired: false)
        let verb = Verb(name: testVerbName, parameters: [parameter, secondParameter]) { (parameters) in
            XCTAssert(parameters?.count == 2, "Must have two parameters")
            XCTAssert(parameters?.first?.parameter.name == testParamName, "Parameter must match")
            XCTAssert(parameters?.first?.value == testParamValue, "Values must match")
            XCTAssert(parameters?.last?.parameter.name == secondParamName, "Parameter must much")
            expectation.fulfill()
        }
        try! CommandLine.parse([verb])
        wait(for: [expectation], timeout: 1)
    }
    
    func testVerbGroup() {
        let firstTestVerbName = "test1"
        let secondTestVerbName = "test2"
        CommandLine.arguments.append(contentsOf: [firstTestVerbName])
        
        let expectation = XCTestExpectation(description: "Verify callback")
        let firstVerb = Verb(name: firstTestVerbName, parameters: nil) { (parameters) in
            expectation.fulfill()
        }
        let secondVerb = Verb(name: secondTestVerbName, parameters: nil) { (parameters) in
            expectation.fulfill()
        }
        let group = Group(name: "verbs", verbs: [firstVerb, secondVerb], callback: nil)
        try! CommandLine.parse([group])
        wait(for: [expectation], timeout: 1)
    }
    
    static var allTests = [
        ("testSingleOption", testSingleOption),
        ("testSingleVerb", testSingleVerb),
        ("testSingleVerbWithParameterValue", testSingleVerbWithParameterValue),
        ("testSingleVerbWithMultipleParametersValue", testSingleVerbWithMultipleParametersValue),
        ("testVerbGroup", testVerbGroup),
    ]
}
