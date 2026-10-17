// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import AVFoundation
import Foundation

/// Camera: the list of cameras and depth sensors. No photo or video is ever captured.
@MainActor
final class CameraPermissionSource: SignalSource {
    let sections: [SignalSection] = [.camera]
    let permission: PermissionKind? = .camera

    func permissionState() -> PermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .granted
        case .notDetermined: return .notAsked
        case .denied, .restricted: return .denied
        @unknown default: return .denied
        }
    }

    func requestPermission() async -> PermissionState {
        let current = permissionState()
        guard current == .notAsked else { return current }
        _ = await AVCaptureDevice.requestAccess(for: .video)
        return permissionState()
    }

    func read() async -> [SignalReading] {
        guard permissionState() == .granted else { return [] }

        // Physical lenses and sensors only; the combined "dual" and "triple" cameras are made
        // from these.
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera,
                          .builtInTrueDepthCamera, .builtInLiDARDepthCamera, .external],
            mediaType: nil,
            position: .unspecified
        )
        let devices = session.devices
        guard !devices.isEmpty else {
            return [SignalReading(id: "cam-list", value: "No cameras found")]
        }

        let back = devices.filter { $0.position == .back }.count
        let front = devices.filter { $0.position == .front }.count
        let other = devices.count - back - front

        var parts: [String] = []
        if back > 0 { parts.append("\(back) on the back") }
        if front > 0 { parts.append("\(front) on the front") }
        if other > 0 { parts.append("\(other) connected") }
        let value = "\(PermissionText.count(devices.count, "camera")): \(parts.joined(separator: ", "))"

        var items = devices.map { device -> String in
            let side: String
            switch device.position {
            case .back: side = "Back"
            case .front: side = "Front"
            default: side = "Connected"
            }
            let view = device.activeFormat.videoFieldOfView
            let field = view > 0 ? ", \(Int(view.rounded()))° view" : ""
            return "\(side): \(device.localizedName)\(field)"
        }
        if devices.contains(where: { $0.deviceType == .builtInLiDARDepthCamera }) {
            items.append("Has a LiDAR depth sensor, found only on Pro models")
        }
        return [SignalReading(id: "cam-list", value: value, items: items)]
    }
}
