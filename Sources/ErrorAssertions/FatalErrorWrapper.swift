//
//  FatalErrorWrapper.swift
//  ErrorAssertions
//
//  Created by Jeff Kelley on 7/1/19.
//

@inlinable
public func fatalError(_ error: Error,
                       file: StaticString = #file,
                       line: UInt = #line) -> Never {
    FatalErrorUtilities.fatalErrorClosure(error, file, line)
}

@inlinable
public func fatalError(_ message: @autoclosure () -> String = String(),
                       file: StaticString = #file,
                       line: UInt = #line) -> Never {
    fatalError(AnonymousError(string: message()),
               file: file,
               line: line)
}

public struct FatalErrorUtilities {
    
    public typealias FatalErrorClosure = (Error, StaticString, UInt) -> Never
    
    @usableFromInline
    internal static var fatalErrorClosure = defaultFatalErrorClosure
    
    private static let defaultFatalErrorClosure = {
        (error: Error, file: StaticString, line: UInt) -> Never in
        Swift.fatalError(error.localizedDescription,
                         file: file,
                         line: line)
    }
    
    #if DEBUG
    static public func replaceFatalError(
        closure: @escaping FatalErrorClosure
    ) -> RestorationHandler {
        fatalErrorClosure = closure
        return restoreFatalError
    }
    
    static private func restoreFatalError() {
        fatalErrorClosure = defaultFatalErrorClosure
    }
    #endif
    
}
