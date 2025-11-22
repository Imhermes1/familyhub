import Foundation
import CoreBluetooth
import Combine

@MainActor
class PulseBluetoothManager: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    @Published var isBluetoothEnabled = false
    @Published var connectedDevices: Set<String> = []

    private var previousDevices: Set<String> = []
    private var onCarConnect: (() -> Void)?
    private var onCarDisconnect: (() -> Void)?

    // List of known car Bluetooth device name patterns
    private let carDevicePatterns = [
        "car", "bmw", "audi", "tesla", "mercedes", "ford", "toyota",
        "honda", "chevrolet", "nissan", "volkswagen", "volvo", "lexus",
        "mazda", "subaru", "jeep", "gmc", "dodge", "chrysler", "buick",
        "carplay", "android auto"
    ]

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Configuration

    func setCarConnectionHandlers(
        onConnect: @escaping () -> Void,
        onDisconnect: @escaping () -> Void
    ) {
        self.onCarConnect = onConnect
        self.onCarDisconnect = onDisconnect
    }

    // MARK: - Device Detection

    func startMonitoring() {
        guard isBluetoothEnabled else {
            print("Bluetooth is not enabled")
            return
        }

        // In iOS, we can't directly monitor all Bluetooth connections
        // This is a simplified approach - in production, you might use:
        // 1. External Accessory framework for MFi accessories
        // 2. Background app refresh when BT state changes
        // 3. Notification observers for audio route changes

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioRouteChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    func stopMonitoring() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func audioRouteChanged(notification: Notification) {
        Task { @MainActor in
            guard let userInfo = notification.userInfo,
                  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
            }

            switch reason {
            case .newDeviceAvailable:
                // Bluetooth device connected
                checkForCarConnection()

            case .oldDeviceUnavailable:
                // Bluetooth device disconnected
                checkForCarDisconnection()

            default:
                break
            }
        }
    }

    private func checkForCarConnection() {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        let isCarConnected = currentRoute.outputs.contains { output in
            isCarAudioDevice(output)
        }

        if isCarConnected && !previousDevices.contains("car") {
            print("Car Bluetooth connected")
            previousDevices.insert("car")
            onCarConnect?()

            PostHogManager.shared.track("auto_update_triggered", properties: [
                "trigger_source": "bluetooth",
                "event": "connect"
            ])
        }
    }

    private func checkForCarDisconnection() {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        let isCarConnected = currentRoute.outputs.contains { output in
            isCarAudioDevice(output)
        }

        if !isCarConnected && previousDevices.contains("car") {
            print("Car Bluetooth disconnected")
            previousDevices.remove("car")
            onCarDisconnect?()

            PostHogManager.shared.track("auto_update_triggered", properties: [
                "trigger_source": "bluetooth",
                "event": "disconnect"
            ])
        }
    }

    private func isCarAudioDevice(_ output: AVAudioSessionPortDescription) -> Bool {
        // Check if it's a Bluetooth output
        guard output.portType == .bluetoothA2DP ||
              output.portType == .bluetoothHFP ||
              output.portType == .bluetoothLE ||
              output.portType == .carAudio else {
            return false
        }

        // Check for CarPlay
        if output.portType == .carAudio {
            return true
        }

        // Check device name for car patterns
        let deviceName = output.portName.lowercased()
        return carDevicePatterns.contains { pattern in
            deviceName.contains(pattern)
        }
    }

    // MARK: - Manual Testing

    func simulateCarConnect() {
        print("Simulating car Bluetooth connect")
        onCarConnect?()
    }

    func simulateCarDisconnect() {
        print("Simulating car Bluetooth disconnect")
        onCarDisconnect?()
    }
}

// MARK: - CBCentralManagerDelegate

extension PulseBluetoothManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                isBluetoothEnabled = true
                print("Bluetooth is powered on")

            case .poweredOff:
                isBluetoothEnabled = false
                print("Bluetooth is powered off")

            case .unauthorized:
                print("Bluetooth permission not granted")

            case .unsupported:
                print("Bluetooth not supported on this device")

            default:
                break
            }
        }
    }
}

// MARK: - Import AVFoundation

import AVFoundation
