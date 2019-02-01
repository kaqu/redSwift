//
//  DashboardTests.swift
//  ModuleTests
//
//  Created by Kacper Kaliński on 01/02/2019.
//  Copyright © 2019 Miquido. All rights reserved.
//

@testable import Module
import XCTest

class DashboardTests: XCTestCase {
    func testExample() {
        var state: Dashboard.State = .init()
        var (changes, tasks) = ([Dashboard.Change](), [Dashboard.Task]())

        (changes, tasks) = Dashboard.initialize(state: state)
        XCTAssertTrue(changes.isEmpty)
        XCTAssertTrue(tasks.isEmpty)

        (changes, tasks) = Dashboard.dispatcher(state: &state, message: .showDetail)
        XCTAssertTrue(changes.isEmpty)
        XCTAssertFalse(tasks.isEmpty)

        (changes, tasks) = Dashboard.dispatcher(state: &state, message: .backFromDetail)
        XCTAssertFalse(changes.isEmpty)
        XCTAssertTrue(tasks.isEmpty)

        var parentHandle: (Root.Message) -> Void
            = { message in
            switch message {
                case .setupDashboard:
                    break
            }
        }
        var selfHandle: (Dashboard.Message) -> Void
            = { message in
            switch message {
                case .showDetail:
                    XCTFail()
                case .setupDetail:
                    break
                case .backFromDetail:
                    XCTFail()
            }
        }
        let worker = Dashboard.workerFactory(context: Dashboard.Context(parentHandle: parentHandle))
        worker(selfHandle, .prepareDetail(Detail.State()))
    }
}
