import Foundation
import IOKit.ps

/// Reads the internal battery and reports plug/unplug, low and full events. Does nothing on desktop Macs.
@MainActor
final class BatteryWatcher {
    enum Event { case pluggedIn, unplugged, low(Int), recovered, full }

    var onEvent: ((Event) -> Void)?
    private(set) var isLow = false
    private var last: (percent: Int, plugged: Bool)?
    private var announcedFull = false

    func check() {
        guard let now = Self.read() else { return }
        defer { last = now }

        if let prev = last {
            if now.plugged && !prev.plugged { onEvent?(.pluggedIn) }
            if !now.plugged && prev.plugged { onEvent?(.unplugged) }
        }

        if !now.plugged && now.percent <= 20 && !isLow {
            isLow = true
            onEvent?(.low(now.percent))
        } else if isLow && (now.plugged || now.percent > 25) {
            isLow = false
            onEvent?(.recovered)
        }

        if now.plugged && now.percent >= 100 && !announcedFull && last != nil {
            announcedFull = true
            onEvent?(.full)
        } else if now.percent < 95 {
            announcedFull = false
        }
    }

    private static func read() -> (percent: Int, plugged: Bool)? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
        for source in list {
            guard let desc = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  desc[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                  let current = desc[kIOPSCurrentCapacityKey] as? Int,
                  let max = desc[kIOPSMaxCapacityKey] as? Int, max > 0 else { continue }
            let plugged = desc[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
            return (current * 100 / max, plugged)
        }
        return nil
    }
}
