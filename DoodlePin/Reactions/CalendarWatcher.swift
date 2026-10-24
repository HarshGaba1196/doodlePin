import EventKit

/// Gives a heads-up 10 minutes before an event and again when it starts. Asks for calendar access first.
@MainActor
final class CalendarWatcher {
    var onUpcoming: ((_ title: String, _ minutes: Int) -> Void)?

    private let store = EKEventStore()
    private var announced = Set<String>()

    static var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    static var isDenied: Bool {
        let s = EKEventStore.authorizationStatus(for: .event)
        return s == .denied || s == .restricted
    }

    func requestAccess(_ done: @escaping (Bool) -> Void) {
        if Self.isAuthorized { done(true); return }
        store.requestFullAccessToEvents { granted, _ in
            DispatchQueue.main.async { done(granted) }
        }
    }

    func check() {
        guard Self.isAuthorized else { return }
        let now = Date()
        let predicate = store.predicateForEvents(withStart: now.addingTimeInterval(-60), end: now.addingTimeInterval(11 * 60), calendars: nil)
        for event in store.events(matching: predicate) where !event.isAllDay {
            guard let start = event.startDate else { continue }
            let minutes = Int((start.timeIntervalSince(now) / 60).rounded(.up))
            let key = "\(event.eventIdentifier ?? "")-\(start.timeIntervalSince1970)"
            let title = event.title ?? "Your event"
            if minutes > 1 && minutes <= 10, announced.insert(key + "-soon").inserted {
                onUpcoming?(title, minutes)
            } else if minutes >= 0 && minutes <= 1, announced.insert(key + "-now").inserted {
                onUpcoming?(title, 0)
            }
        }
    }
}
