//
//  AppDelegate.swift
//  RedSwift
//
//  Created by Kacper Kaliński on 31/01/2019.
//  Copyright © 2019 Miquido. All rights reserved.
//

import UIKit
import Module

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let rootController = Root.build(context: Void(), initialState: Root.State())
}
