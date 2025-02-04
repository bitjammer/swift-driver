//===------------------------ BidirectionalMapTests.swift -----------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import SwiftDriver

class BidirectionalMapTests: XCTestCase {
  func testBiDiMap() {
    func test(_ biMapToTest: BidirectionalMap<Int, String>) {
      zip(biMapToTest.map{$0}.sorted {$0.0 < $1.0}, testContents).forEach {
        XCTAssertEqual($0.0, $1.0)
        XCTAssertEqual($0.1, $1.1)
      }
      for (i, s) in testContents.map({$0}) {
        XCTAssertEqual(biMapToTest[i], s)
        XCTAssertEqual(biMapToTest[s], i)
        XCTAssertNotNil(biMapToTest[i])
        XCTAssertNotNil(biMapToTest[s])
        XCTAssertNil(biMapToTest[-1])
        XCTAssertNil(biMapToTest["gazorp"])
      }
    }
    
    var biMap = BidirectionalMap<Int, String>()
    var testContents = (0..<3).map {($0, String($0))}
    for (i, s) in testContents {
      biMap[i] = s
    }
    test(biMap)
    biMap[testContents.count] = nil
    test(biMap)
    biMap["gazorp"] = nil
    test(biMap)

    let removed = testContents.removeFirst()
    var biMap2 = biMap
    biMap[removed.0] = nil
    biMap2[removed.1] = nil
    test(biMap)
    test(biMap2)
  }

  func testDirectionality() {
    var biMap = BidirectionalMap<Int, String>()
    biMap[1] = "Hello"
    XCTAssertEqual(biMap["Hello"], 1)
    XCTAssertEqual(biMap[1], "Hello")
    biMap[2] = "World"
    XCTAssertEqual(biMap["World"], 2)
    XCTAssertEqual(biMap[2], "World")

    biMap["World"] = 3
    XCTAssertEqual(biMap["World"], 3)
    XCTAssertEqual(biMap[3], "World")
    biMap["Hello"] = 4
    XCTAssertEqual(biMap["Hello"], 4)
    XCTAssertEqual(biMap[4], "Hello")
  }
}
