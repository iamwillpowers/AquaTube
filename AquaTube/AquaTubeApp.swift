///
/// AquaTubeApp.swift
/// AquaTube
/// Created by William Powers on 7/11/23.
/// Copyright © 2023 ION6, LLC. All rights reserved.
///

import SwiftUI
import CoreBluetooth

@main
struct AquaTubeApp: App {
    var body: some Scene {
        WindowGroup {
            PeripheralListView()
        }
    }
}
