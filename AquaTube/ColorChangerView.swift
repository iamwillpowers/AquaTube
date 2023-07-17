///
/// ColorChanger.swift
/// AquaTube
/// Created by William Powers on 7/13/23.
/// Copyright © 2023 ION6, LLC. All rights reserved.
///

import SwiftUI
import CoreBluetooth

struct ColorChangerView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var bgColor = Color(.sRGB, red: 0.0, green: 0.5, blue: 1.0)
    @StateObject var manager: BluetoothManager
    var peripheral: CBPeripheral

    var body: some View {
        VStack(alignment: .leading) {
            Text(peripheral.state.description)
            Text("\(peripheral.name ?? "")")
                .font(.headline)
            ColorPicker("Set an individual color.", selection: $bgColor, supportsOpacity: false)
                .onChange(of: bgColor) { newValue in
                    guard let cgColor = newValue.cgColor else { return }
                    manager.setColor(values: cgColor.componentsToUInt8())
                }
            Spacer()
        }
        .navigationTitle("Color Changer")
        .padding(.top, 10)
        .padding(.leading, 16)
        .onChange(of: manager.hasInitializedConnection) { isConnected in
            if isConnected == false {
                manager.clearPeripherals()
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

extension CBPeripheralState {
    var description: String {
        switch self {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnecting:
            return "Disconnecting"
        case .disconnected:
            return "Disconnected"
        @unknown default:
            return "Unknown"
        }
    }
}

struct PeripheralStateLabel: View {
    var state: CBPeripheralState

    var body: some View {
        switch state {
        case .connected:
            Text("Connected")
        case .connecting:
            Text("Connecting")
        case .disconnecting:
            Text("Disconnecting")
        case .disconnected:
            Text("Disconnected")
        @unknown default:
            Text("Unknown")
        }
    }
}

extension CGColor {
    func componentsToUInt8() -> [UInt8] {
        guard let colorComponents = components else {
            return []
        }

        return colorComponents.map { component -> UInt8 in
            UInt8(component * 255.0)
        }
    }
}
