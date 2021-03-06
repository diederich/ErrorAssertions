//
//  AssertExpectations.swift
//  ErrorAssertionExpectations
//
//  Created by Jeff Kelley on 7/1/19.
//

import ErrorAssertions
import XCTest

extension XCTestCase {
    
    private func replaceAssert(
        _ handler: @escaping (Error) -> Void
    ) -> RestorationHandler {
        let assertRestorationHandler = AssertUtilities.replaceAssert {
            (condition, error, _, _) in
            if !condition {
                handler(error)
                unreachable()
            }
        }
 
        let assertionFailureRestorationHandler = 
            AssertUtilities.replaceAssertionFailure {
                (error, _, _) in
                handler(error)
                unreachable()
        }
        
        return {
            assertRestorationHandler() 
            assertionFailureRestorationHandler()
        }
    }
    
    private func wrapWithAssertions(_ testcase: @escaping () -> Void,
                                    timeout: TimeInterval,
                                    handler: ((Error) -> Void)? = nil) {
        let expectation = self.expectation(
            description: "Expecting an assertion failure to occur"
        )
        
        let restoration = replaceAssert { error in
            handler?(error)
            expectation.fulfill()
        }
        
        defer { restoration() }
        
        let thread = ClosureThread(testcase)
        thread.start()
        defer { thread.cancel() }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    /// Executes the `testcase` closure and expects it to produce a specific
    /// assertion failure.
    ///
    /// - Parameters:
    ///   - expectedError: The `Error` you expect `testcase` to pass to
    ///                    `assert()` or `assertionFailure()`.
    ///   - timeout: How long to wait for `testcase` to produce its error.
    ///              Defaults to 2 seconds.
    ///   - file: The test file. By default, this will be the file from which
    ///           you’re calling this method.
    ///   - line: The line number in `file` where this is called.
    ///   - testcase: The closure to run that produces the error.
    public func expectAssertionFailure<T: Error>(
        expectedError: T,
        timeout: TimeInterval = 2,
        file: StaticString = #file,
        line: UInt = #line,
        testcase: @escaping () -> Void
    ) where T: Equatable {
        let equalityExpectation = expectation(
            description: "The error was equal to the expected value"
        )
        
        wrapWithAssertions(testcase, timeout: timeout) { error in
            if let error = error as? T, error == expectedError {
                equalityExpectation.fulfill()
            }
        }
        
        wait(for: [equalityExpectation], timeout: timeout)
    }
    
    /// Executes the `testcase` closure and expects it to produce a specific
    /// assertion failure message.
    ///
    /// - Parameters:
    ///   - message: The `String` you expect `testcase` to pass to
    ///              `assert()`.
    ///   - timeout: How long to wait for `testcase` to produce its error.
    ///              Defaults to 2 seconds.
    ///   - file: The test file. By default, this will be the file from which
    ///           you’re calling this method.
    ///   - line: The line number in `file` where this is called.
    ///   - testcase: The closure to run that produces the error.
    public func expectAssertionFailure(
        expectedMessage message: String,
        timeout: TimeInterval = 2,
        file: StaticString = #file,
        line: UInt = #line,
        testcase: @escaping () -> Void
    ) {
        expectAssertionFailure(
            expectedError: AnonymousError(string: message),
            timeout: timeout,
            file: file,
            line: line,
            testcase: testcase)
    }
    
    /// Executes the `testcase` closure and expects it to produce any assertion
    /// failure.
    ///
    /// - Parameters:
    ///   - timeout: How long to wait for `testcase` to produce its error.
    ///              Defaults to 2 seconds.
    ///   - file: The test file. By default, this will be the file from which
    ///           you’re calling this method.
    ///   - line: The line number in `file` where this is called.
    ///   - testcase: The closure to run that produces the error.
    public func expectAssertionFailure(
        timeout: TimeInterval = 2,
        file: StaticString = #file,
        line: UInt = #line,
        testcase: @escaping () -> Void
    ) {
        wrapWithAssertions(testcase, timeout: timeout)
    }
    
    /// Executes the `testcase` closure and expects it finish without producing
    /// any assertion failures.
    ///
    /// - Parameters:
    ///   - timeout: How long to wait for `testcase` to finish. Defaults to 2
    ///              seconds.
    ///   - file: The test file. By default, this will be the file from which
    ///           you’re calling this method.
    ///   - line: The line number in `file` where this is called.
    ///   - testcase: The closure to run.
    public func expectNoAssertionFailure(
        timeout: TimeInterval = 2,
        file: StaticString = #file,
        line: UInt = #line,
        testcase: @escaping () -> Void
    ) {
        let expectation = self.expectation(
            description: "Expecting no assertion failure to occur"
        )
        
        let restoration = replaceAssert { _ in
            XCTFail("Received an assertion failure when expecting none",
                    file: file,
                    line: line)
            
            expectation.fulfill()
        }
        
        defer { restoration() }
        
        let thread = ClosureThread {
            testcase()
            expectation.fulfill()
        }
        
        thread.start()
        defer { thread.cancel() }
        
        wait(for: [expectation], timeout: timeout)
    }
    
}
