//===----------- DependencyGraphSerializationTests.swift ------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
@_spi(Testing) import SwiftDriver
import TSCBasic

class DependencyGraphSerializationTests: XCTestCase, ModuleDependencyGraphMocker {
  static let mockGraphCreator = MockModuleDependencyGraphCreator(maxIndex: 12)

  func roundTrip(_ graph: ModuleDependencyGraph) throws {
    let mockPath = VirtualPath.absolute(AbsolutePath("/module-dependency-graph"))
    let fs = InMemoryFileSystem()
    try graph.write(to: mockPath, on: fs, compilerVersion: "Swift 99")

    let deserializedGraph = try ModuleDependencyGraph.read(from: mockPath,
                                                           info: .mock(fileSystem: fs))!
    var originalNodes = Set<ModuleDependencyGraph.Node>()
    graph.nodeFinder.forEachNode {
      originalNodes.insert($0)
    }

    var deserializedNodes = Set<ModuleDependencyGraph.Node>()
    deserializedGraph.nodeFinder.forEachNode {
      deserializedNodes.insert($0)
    }

    XCTAssertTrue(originalNodes == deserializedNodes,
                  "Round trip failed! Symmetric difference - \(originalNodes.symmetricDifference(deserializedNodes))")

    XCTAssertEqual(graph.nodeFinder.usesByDef, deserializedGraph.nodeFinder.usesByDef)
    XCTAssertEqual(graph.inputDependencySourceMap, deserializedGraph.inputDependencySourceMap)
    XCTAssertEqual(graph.fingerprintedExternalDependencies,
                   deserializedGraph.fingerprintedExternalDependencies)
  }

  func testRoundTripFixtures() throws {
    struct GraphFixture {
      var commands: [LoadCommand]

      enum LoadCommand {
        case load(index: Int, nodes: [MockDependencyKind: [String]], fingerprint: String? = nil)
        case reload(index: Int, nodes: [MockDependencyKind: [String]], fingerprint: String? = nil)
      }
    }
    
    let fixtures: [GraphFixture] = [
      GraphFixture(commands: []),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.topLevel: ["a->", "b->"]]),
        .load(index: 1, nodes: [.nominal: ["c->", "d->"]]),
        .load(index: 2, nodes: [.topLevel: ["e", "f"]]),
        .load(index: 3, nodes: [.nominal: ["g", "h"]]),
        .load(index: 4, nodes: [.dynamicLookup: ["i", "j"]]),
        .load(index: 5, nodes: [.dynamicLookup: ["k->", "l->"]]),
        .load(index: 6, nodes: [.member: ["m,mm", "n,nn"]]),
        .load(index: 7, nodes: [.member: ["o,oo->", "p,pp->"]]),
        .load(index: 8, nodes: [.externalDepend: ["/foo->", "/bar->"]]),
        .load(index: 9, nodes: [
          .nominal: ["a", "b", "c->", "d->"],
          .topLevel: ["b", "c", "d->", "a->"]
        ])
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.topLevel: ["a0", "a->"]]),
        .load(index: 1, nodes: [.topLevel: ["b0", "b->"]]),
        .load(index: 2, nodes: [.topLevel: ["c0", "c->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["a", "a->"]]),
        .load(index: 1, nodes: [.topLevel: ["a", "b->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["a->", "b"]]),
        .load(index: 1, nodes: [.topLevel: ["b->", "a"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.member: ["a,aa"]]),
        .load(index: 1, nodes: [.member: ["a,bb->"]]),
        .load(index: 2, nodes: [.potentialMember: ["a"]]),
        .load(index: 3, nodes: [.member: ["b,aa->"]]),
        .load(index: 4, nodes: [.member: ["b,bb->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.topLevel: ["a", "b", "c"]]),
        .load(index: 1, nodes: [.topLevel: ["x->", "b->", "z->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.topLevel: ["a->", "b->", "c->"]]),
        .load(index: 1, nodes: [.topLevel: ["x", "b", "z"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["a", "b", "c"]]),
        .load(index: 1, nodes: [.nominal: ["x->", "b->", "z->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["a"], .topLevel: ["a"]]),
        .load(index: 1, nodes: [.nominal: ["a->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["a"], .topLevel: ["a"]]),
        .load(index: 1, nodes: [.nominal: ["a->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["a"]]),
        .load(index: 1, nodes: [.nominal: ["a->"], .topLevel: ["a->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["a"], .topLevel: ["a"]]),
        .load(index: 1, nodes: [.nominal: ["a->"], .topLevel: ["a->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.dynamicLookup: ["a", "b", "c"]]),
        .load(index: 1, nodes: [.dynamicLookup: ["x->", "b->", "z->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.member: ["a,aa", "b,bb", "c,cc"]]),
        .load(index: 1, nodes: [.member: ["x,xx->", "b,bb->", "z,zz->"]])
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["a", "b", "c"]]),
        .load(index: 1, nodes: [.nominal: ["x->", "b->", "z->"]]),
        .load(index: 2, nodes: [.nominal: ["q->", "b->", "s->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["a", "b", "c"]]),
        .load(index: 1, nodes: [.nominal: ["x->", "b->", "z->"]]),
        .load(index: 2, nodes: [.nominal: ["q->", "r->", "c->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["a", "b", "c"]]),
        .load(index: 1, nodes: [.nominal: ["x->", "b->", "z"]]),
        .load(index: 2, nodes: [.nominal: ["z->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["a", "b", "c"]]),
        .load(index: 1, nodes: [.nominal: ["x->", "b->", "#z"]]),
        .load(index: 2, nodes: [.nominal: ["#z->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.topLevel: ["a", "b", "c"]]),
        .load(index: 1, nodes: [.topLevel: ["x->", "#b->"], .nominal: ["z"]]),
        .load(index: 2, nodes: [.nominal: ["z->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.topLevel: ["a", "b"]]),
        .load(index: 1, nodes: [.topLevel: ["a->", "z"]]),
        .load(index: 2, nodes: [.topLevel: ["z->"]]),
        .load(index: 10, nodes: [.topLevel: ["y", "z", "q->"]]),
        .load(index: 11, nodes: [.topLevel: ["y->"]]),
        .load(index: 12, nodes: [.topLevel: ["q->", "q"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["a"]]),
        .load(index: 1, nodes: [.nominal: ["a->"]]),
        .load(index: 2, nodes: [.nominal: ["b->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["a"]]),
        .load(index: 1, nodes: [.nominal: ["a->"]]),
        .load(index: 2, nodes: [.nominal: ["b->"]]),
        .reload(index: 0, nodes: [.nominal: ["a", "b"]])
      ]),
      GraphFixture(commands: [
        .reload(index: 1, nodes: [.nominal: ["b", "a->"]])
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["A1@1", "A2@2", "A1->"]]),
        .load(index: 1, nodes: [.nominal: ["B1", "A1->"]]),
        .load(index: 2, nodes: [.nominal: ["C1", "A2->"]]),
        .load(index: 3, nodes: [.nominal: ["D1"]]),
        .reload(index: 0, nodes: [.nominal: ["A1", "A2"]], fingerprint: "changed")
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["A"]]),
        .load(index: 1, nodes: [.nominal: ["B", "C", "A->"]]),
        .load(index: 2, nodes: [.nominal: ["B->"]]),
        .load(index: 3, nodes: [.nominal: ["C->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["A"]]),
        .load(index: 1, nodes: [.nominal: ["B", "C", "A->B"]]),
        .load(index: 2, nodes: [.nominal: ["B->"]]),
        .load(index: 3, nodes: [.nominal: ["C->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["A1@1", "A2@2"]]),
        .load(index: 1, nodes: [.nominal: ["B1", "C1", "A1->"]]),
        .load(index: 2, nodes: [.nominal: ["B1->"]]),
        .load(index: 3, nodes: [.nominal: ["C1->"]]),
        .load(index: 4, nodes: [.nominal: ["B2", "C2", "A2->"]]),
        .load(index: 5, nodes: [.nominal: ["B2->"]]),
        .load(index: 6, nodes: [.nominal: ["C2->"]]),
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.nominal: ["A1@1", "A2@2"]]),
        .load(index: 1, nodes: [.nominal: ["B1", "C1", "A1->B1"]]),
        .load(index: 2, nodes: [.nominal: ["B1->"]]),
        .load(index: 3, nodes: [.nominal: ["C1->"]]),
        .load(index: 4, nodes: [.nominal: ["B2", "C2", "A2->B2"]]),
        .load(index: 5, nodes: [.nominal: ["B2->"]]),
        .load(index: 6, nodes: [.nominal: ["C2->"]]),
        .reload(index: 0, nodes: [.nominal: ["A1@11", "A2@2"]])
      ]),
      GraphFixture(commands: [
        .load(index: 0, nodes: [.externalDepend: ["/foo->", "/bar->"]], fingerprint: "ABCDEFG"),
        .reload(index: 0, nodes: [.externalDepend: ["/foo->", "/bar->"]], fingerprint: "HIJKLMNOP"),
      ]),
    ]

    for fixture in fixtures {
      let graph = Self.mockGraphCreator.mockUpAGraph()
      for loadCommand in fixture.commands {
        switch loadCommand {
        case .load(index: let index, nodes: let nodes, fingerprint: let fingerprint):
          graph.simulateLoad(index, nodes, fingerprint)
        case .reload(index: let index, nodes: let nodes, fingerprint: let fingerprint):
          _ = graph.simulateReload(index, nodes, fingerprint)
        }
      }
      try roundTrip(graph)
    }
  }
}
