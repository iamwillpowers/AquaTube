///
/// PopupView.swift
/// AquaTube
/// Created by William Powers on 7/14/23.
/// Copyright © 2023 ION6, LLC. All rights reserved.
///

import SwiftUI
import CoreBluetooth

struct PopupView: View {
    var state: CBPeripheralState

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray)
            .opacity(0.1)
            .frame(width: 200, height: 100)
            .overlay(
                Text(state.description)
                    .font(.headline)
                    .foregroundColor(.white)
            )
    }
}
