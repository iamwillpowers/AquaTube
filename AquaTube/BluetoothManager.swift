import CoreBluetooth

final class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var peripherals: [CBPeripheral] = []
    @Published var rssiForIdentifier: [UUID: Int] = [:]
    @Published var colorWheelCharacteristic: CBCharacteristic?
    @Published var colorCommandCharacteristic: CBCharacteristic?

    // A timer that fires every second to update the RSSI
    private var timer: Timer?

    private lazy var centralManager = CBCentralManager(delegate: self, queue: nil)

    // UUIDs of the BLE service and characteristics on the Arduino Nano 33 BLE
    private static let serviceUUID = CBUUID(string: "19B10010-E8F2-537E-4F6C-D104768A1214")
    private static let colorWheelCharacteristicUUID = CBUUID(string: "19B10011-E8F2-537E-4F6C-D104768A1214")
    private static let colorCommandCharacteristicUUID = CBUUID(string: "19B10012-E8F2-537E-4F6C-D104768A1214")

    var connectedPeripheral: CBPeripheral? {
        peripherals.first { $0.state == .connected }
    }

    var hasInitializedConnection: Bool {
        connectedPeripheral != nil && colorWheelCharacteristic != nil && colorCommandCharacteristic != nil
    }

    func connectToDevice(peripheral: CBPeripheral) {
        guard peripheral.state != .connected && peripheral.state != .connecting else { return }
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    func scanForPeripherals() {
        guard centralManager.state == .poweredOn else { return }
        // Bluetooth is powered on, start scanning for peripherals
        if centralManager.isScanning == false {
           centralManager.scanForPeripherals(withServices: [Self.serviceUUID], options: nil)

           // After a short interval, stop scanning.
           DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
               self.centralManager.stopScan()

               // After another short interval, start scanning again.
               DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                   self.scanForPeripherals()
               }
           }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        scanForPeripherals()
    }

    func clearPeripherals() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.peripherals = []
            self.rssiForIdentifier = [:]
            self.colorWheelCharacteristic = nil
            self.colorCommandCharacteristic = nil
        }
    }

    func centralManager(
            _ central: CBCentralManager,
            didDiscover peripheral: CBPeripheral,
            advertisementData: [String : Any],
            rssi RSSI: NSNumber
        ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
                self.peripherals.append(peripheral)
            }
            peripheral.delegate = self
            self.rssiForIdentifier[peripheral.identifier] = Int(truncating: RSSI)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Connected to the Arduino Nano 33 BLE, discover services
        peripheral.readRSSI()
        connectedPeripheral?.discoverServices([Self.serviceUUID])
    }

    func setColor(values: [UInt8]) {
        guard
            let peripheral = connectedPeripheral,
            let characteristic = colorWheelCharacteristic
        else { return }

        // this *must* be withResponse or it won't work
        peripheral.writeValue(Data(values), for: characteristic, type: .withResponse)
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard
            connectedPeripheral?.identifier == peripheral.identifier,
            let services = peripheral.services
        else { return }

        for service in services {
            guard service.uuid == Self.serviceUUID else { continue }
            // Found the service, discover characteristics
            peripheral.discoverCharacteristics([Self.colorWheelCharacteristicUUID, Self.colorCommandCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            switch characteristic.uuid {
            case Self.colorWheelCharacteristicUUID:
                colorWheelCharacteristic = characteristic
            case Self.colorCommandCharacteristicUUID:
                colorCommandCharacteristic = characteristic
            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else { return }
        DispatchQueue.main.async { [weak self] in
            self?.rssiForIdentifier[peripheral.identifier] = Int(truncating: RSSI)
        }
    }
}
