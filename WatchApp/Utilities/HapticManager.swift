import WatchKit

final class HapticManager: Sendable {
    static let shared = HapticManager()
    private init() {}

    enum HapticType: Sendable {
        case messageSent
        case responseComplete
        case taskCreated
        case taskComplete
        case taskFailed
        case error
        case tap
    }

    func play(_ type: HapticType) {
        let device = WKInterfaceDevice.current()
        switch type {
        case .messageSent:
            device.play(.click)
        case .responseComplete:
            device.play(.success)
        case .taskCreated:
            device.play(.click)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                device.play(.directionUp)
            }
        case .taskComplete:
            device.play(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                device.play(.click)
            }
        case .taskFailed:
            device.play(.failure)
        case .error:
            device.play(.retry)
        case .tap:
            device.play(.click)
        }
    }
}
