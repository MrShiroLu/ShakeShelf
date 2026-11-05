import AppKit
import ServiceManagement
import ShakeCore

enum ShelfCorner: String, CaseIterable {
    case bottomRight, bottomLeft, topRight, topLeft

    var title: String {
        switch self {
        case .bottomRight: "Bottom Right"
        case .bottomLeft: "Bottom Left"
        case .topRight: "Top Right"
        case .topLeft: "Top Left"
        }
    }
}

enum PreviewSize: String, CaseIterable {
    case small, medium, large

    var title: String { rawValue.capitalized }

    var tileWidth: CGFloat {
        switch self {
        case .small: 88
        case .medium: 105
        case .large: 128
        }
    }
}

extension ShakeSensitivity {
    var title: String { rawValue.capitalized }
}

/// User preferences, stored in UserDefaults. `onChange` fires after any of them changes.
final class Settings {
    var onChange: (() -> Void)?

    private let defaults = UserDefaults.standard

    var sensitivity: ShakeSensitivity {
        get { value(forKey: "shakeSensitivity") ?? .medium }
        set { store(newValue.rawValue, forKey: "shakeSensitivity") }
    }

    var corner: ShelfCorner {
        get { value(forKey: "shelfCorner") ?? .bottomRight }
        set { store(newValue.rawValue, forKey: "shelfCorner") }
    }

    var previewSize: PreviewSize {
        get { value(forKey: "previewSize") ?? .medium }
        set { store(newValue.rawValue, forKey: "previewSize") }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: "hasCompletedOnboarding") }
        set { defaults.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    private func value<T: RawRepresentable>(forKey key: String) -> T? where T.RawValue == String {
        defaults.string(forKey: key).flatMap(T.init(rawValue:))
    }

    private func store(_ value: String, forKey key: String) {
        defaults.set(value, forKey: key)
        onChange?()
    }
}

/// A checkbox bound directly to the system's login item state, which the user can
/// also change in System Settings.
final class LaunchAtLoginCheckbox: NSButton {
    convenience init() {
        self.init(checkboxWithTitle: "Launch at login", target: nil, action: nil)
        target = self
        action = #selector(toggled)
        refresh()
    }

    func refresh() {
        state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func toggled() {
        do {
            if state == .on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSAlert(error: error).runModal()
        }
        if SMAppService.mainApp.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
        refresh()
    }
}
