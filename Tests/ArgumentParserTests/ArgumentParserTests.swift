import XCTest
@testable import ArgumentParser

final class ArgumentParserTests: XCTestCase {
    
    override func setUp() {
        CommandLine.arguments = [String(describing: self)]
    }
    
    func testNoArgumentsNotRequired() {
        let testOptionName = "-test"
        
        let option = Option(name: testOptionName, description: "print test description", isRequired: false, callback: nil)
        XCTAssertNoThrow(try CommandLine.parse([option]))
    }
    
    func testNoArgumentsRequired() {
        let testOptionName = "-test"
        
        let option = Option(name: testOptionName, description: "test", isRequired: true, callback: nil)
        XCTAssertThrowsError(try CommandLine.parse([option]))
    }
    
    func testSingleOption() {
        let testOptionName = "-test"
        CommandLine.arguments.append(testOptionName)
        
        let expectation = XCTestExpectation(description: "Verify callback")
        let option = Option(name: testOptionName, description: "test", isRequired: true) { (_) in
            expectation.fulfill()
        }
        XCTAssertNoThrow(try CommandLine.parse([option]))
        wait(for: [expectation], timeout: 1)
    }
    
    func testSingleVerb() {
        let testVerbName = "test"
        CommandLine.arguments.append(testVerbName)
        
        let expectation = XCTestExpectation(description: "Verify callback")
        let verb = Verb(name: testVerbName, description: "test", parameters: nil) { (parameters) in
            expectation.fulfill()
        }
        XCTAssertNoThrow(try CommandLine.parse([verb]))
        wait(for: [expectation], timeout: 1)
    }
    
    func testSingleVerbRequired() {
        let testVerbName = "required"
        
        let verb = Verb(name: testVerbName, description: "test a required verb", parameters: nil) { (parameters) in
            //
        }
        XCTAssertNoThrow(try CommandLine.parse([verb]))
    }
    
    func testSingleVerbWithParameter() {
        let testVerbName = "test"
        let testParamName = "--source"
        CommandLine.arguments.append(contentsOf: [testVerbName, testParamName])
        
        let expectation = XCTestExpectation(description: "Verify callback")
        let parameter = Parameter(name: testParamName, description: "test", isRequired: true, valueRequired: false)
        let verb = Verb(name: testVerbName, description: "test", parameters: [parameter]) { (parameters) in
            XCTAssert(parameters?.count == 1, "Must have one parameter")
            XCTAssert(parameters?.allParamaters.first?.name == testParamName, "Parameter must match")
            XCTAssert(try! parameters?.value(for: testParamName) == nil, "Parameter value must be nil")
            expectation.fulfill()
        }
        XCTAssertNoThrow(try CommandLine.parse([verb]))
        wait(for: [expectation], timeout: 1)
    }
    
    func testSingleVerbWithParameterValue() {
        let testVerbName = "test"
        let testParamName = "--source"
        let testParamValue = "foo"
        CommandLine.arguments.append(contentsOf: [testVerbName, testParamName, testParamValue])
        
        let expectation = XCTestExpectation(description: "Verify callback")
        let parameter = Parameter(name: testParamName, description: "test", isRequired: true, valueRequired: true)
        let verb = Verb(name: testVerbName, description: "test", parameters: [parameter]) { (parameters) in
            XCTAssert(parameters?.count == 1, "Must have one parameter")
            XCTAssert(parameters?.allParamaters.first?.name == testParamName, "Parameter must match")
            XCTAssert(try! parameters?.value(for: testParamName) == testParamValue, "Values must match")
            expectation.fulfill()
        }
        XCTAssertNoThrow(try CommandLine.parse([verb]))
        wait(for: [expectation], timeout: 1)
    }
    
    func testSingleVerbWithMultipleParametersValue() {
        let testVerbName = "test"
        let testParamName = "--source"
        let testParamValue = "foo"
        let secondParamName = "--output"
        CommandLine.arguments.append(contentsOf: [testVerbName, testParamName, testParamValue])
        
        let expectation = XCTestExpectation(description: "Verify callback")
        let parameter = Parameter(name: testParamName, description: "test", isRequired: true, valueRequired: true)
        let secondParameter = Parameter(name: secondParamName, description: "test", isRequired: false, valueRequired: false)
        let verb = Verb(name: testVerbName, description: "test", parameters: [parameter, secondParameter]) { (parameters) in
            XCTAssert(parameters?.count == 2, "Must have two parameters")
            XCTAssert(parameters?.allParamaters.first?.name == testParamName, "Parameter must match")
            XCTAssert(try! parameters?.value(for: testParamName) == testParamValue, "Values must match")
            XCTAssert(parameters?.allParamaters.last?.name == secondParamName, "Parameter must much")
            expectation.fulfill()
        }
        XCTAssertNoThrow(try CommandLine.parse([verb]))
        wait(for: [expectation], timeout: 1)
    }
    
    func testVerbGroup() {
        let firstTestVerbName = "test1"
        let secondTestVerbName = "test2"
        CommandLine.arguments.append(contentsOf: [firstTestVerbName])
        
        let expectation = XCTestExpectation(description: "Verify callback")
        let firstVerb = Verb(name: firstTestVerbName, description: "test1", parameters: nil) { (parameters) in
            expectation.fulfill()
        }
        let secondVerb = Verb(name: secondTestVerbName, description: "test2", parameters: nil) { (parameters) in
            expectation.fulfill()
        }
        let group = Group(name: "verbs", description: "test", verbs: [firstVerb, secondVerb], callback: nil)
        XCTAssertNoThrow(try CommandLine.parse([group]))
        wait(for: [expectation], timeout: 1)
    }
    
    static var allTests = [
        ("testNoArgumentsNotRequired", testNoArgumentsNotRequired),
        ("testNoArgumentsRequired", testNoArgumentsRequired),
        ("testSingleOption", testSingleOption),
        ("testSingleVerb", testSingleVerb),
        ("testSingleVerbRequired", testSingleVerbRequired),
        ("testSingleVerbWithParameterValue", testSingleVerbWithParameterValue),
        ("testSingleVerbWithMultipleParametersValue", testSingleVerbWithMultipleParametersValue),
        ("testVerbGroup", testVerbGroup),
    ]
}
