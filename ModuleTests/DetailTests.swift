//
//  DetailTests.swift
//  ModuleTests
//
//  Created by Kacper Kaliński on 01/02/2019.
//  Copyright © 2019 Miquido. All rights reserved.
//

@testable import Module
import XCTest

class DetailTests: XCTestCase {
    func testExample() {
        var state: Detail.State = .init()
        var (changes, tasks) = ([Detail.Change](), [Detail.Task]())

        (changes, tasks) = Detail.initialize(state: state)
        XCTAssertTrue(changes.isEmpty)
        XCTAssertTrue(tasks.isEmpty)

        (changes, tasks) = Detail.dispatcher(state: &state, message: .goBack)
        XCTAssertTrue(changes.isEmpty)
        XCTAssertFalse(tasks.isEmpty)

        var parentHandle: (Dashboard.Message) -> Void
            = { message in
            switch message {
                case .showDetail:
                    XCTFail()
                case .setupDetail:
                    XCTFail()
                case .backFromDetail:
                    break
            }
        }
        var selfHandle: (Detail.Message) -> Void
            = { message in
            switch message {
                case .goBack:
                    break
            }
        }
        let worker = Detail.workerFactory(context: Detail.Context(parentHandle: parentHandle))
    }
}
