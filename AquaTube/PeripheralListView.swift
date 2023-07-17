///
/// PeripheralListView.swift
/// AquaTube
/// Created by William Powers on 7/15/23.
/// Copyright © 2023 ION6, LLC. All rights reserved.
///

import SwiftUI
import CoreBluetooth

struct PeripheralListView: View {
    @StateObject var manager = BluetoothManager()
    @State private var selectedPeripheral: CBPeripheral?
    
    var body: some View {
        ZStack {
            NavigationStack {
                List {
                    if manager.peripherals.isEmpty {
                        Text("Searching for devices...")
                            .font(.headline)
                            .listRowSeparator(.hidden)
                    } else {
                        Section() {
                            ForEach(manager.peripherals, id: \.self) { peripheral in
                                PeripheralItemView(manager: manager, peripheral: peripheral)
                                    .onTapGesture {
                                        manager.connectToDevice(peripheral: peripheral)
                                        selectedPeripheral = peripheral
                                    }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .navigationTitle("Peripherals")
                .navigationDestination(isPresented: Binding<Bool>(
                    get: { manager.hasInitializedConnection },
                    set: { _ in }
                )) {
                    if let peripheral = manager.connectedPeripheral {
                        ColorChangerView(manager: manager, peripheral: peripheral)
                            .navigationBarBackButtonHidden(true)
                    }
                }
                .refreshable {
                    manager.scanForPeripherals()
                }
            }
            .onAppear() {
                manager.scanForPeripherals()
            }
        }
        .overlay() {
            if let peripheral = selectedPeripheral, peripheral.state != .connected {
                PopupView(state: peripheral.state)
            }
        }
        .preferredColorScheme(.dark)
    }
}
