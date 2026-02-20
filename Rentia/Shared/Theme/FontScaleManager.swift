import SwiftUI

@Observable
final class FontScaleManager {
    @ObservationIgnored
    @AppStorage("fontScale") private var storedFontScale: Double = 1.0
    private var observedFontScale: Double = 1.0

    @ObservationIgnored
    private var defaultsObserver: NSObjectProtocol?

    init() {
        self.observedFontScale = self.storedFontScale
        self.defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let newValue = UserDefaults.standard.object(forKey: "fontScale") as? Double ?? 1.0
            if self.observedFontScale != newValue {
                self.observedFontScale = newValue
            }
        }
    }

    // Observable proxy to the stored value to avoid Observation/AppStorage collision.
    var fontScale: Double {
        get { observedFontScale }
        set {
            observedFontScale = newValue
            storedFontScale = newValue
        }
    }

    // Provides a DynamicTypeSize override based on our scale.
    // We map a few common steps to keep UI stable.
    var dynamicTypeSize: DynamicTypeSize? {
        // Map discrete steps: 0.85, 1.0, 1.15, 1.3 -> sizes below/above .medium
        switch fontScale {
        case ..<0.9:
            return .xSmall
        case 0.9..<1.05:
            return .medium
        case 1.05..<1.22:
            return .xLarge
        default:
            return .xxLarge
        }
    }

    deinit {
        if let observer = defaultsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
