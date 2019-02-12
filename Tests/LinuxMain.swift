import XCTest

import collapserTests

var tests = [XCTestCaseEntry]()
tests += collapserTests.allTests()
XCTMain(tests)