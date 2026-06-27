import Foundation
import Observation

@Observable
final class AdminAuthStore {
    static let defaultPassword = "111111"

    private let passwordKey = "adminPassword"
    private let passwordChangedKey = "adminPasswordHasChanged"
    private(set) var isUnlocked = false

    var shouldShowDefaultPasswordHint: Bool {
        !UserDefaults.standard.bool(forKey: passwordChangedKey)
    }

    var storedPassword: String {
        get { UserDefaults.standard.string(forKey: passwordKey) ?? Self.defaultPassword }
        set { UserDefaults.standard.set(newValue, forKey: passwordKey) }
    }

    @discardableResult
    func unlock(with input: String) -> Bool {
        guard input == storedPassword else { return false }
        isUnlocked = true
        return true
    }

    func lock() {
        isUnlocked = false
    }

    @discardableResult
    func changePassword(current: String, new: String) -> Bool {
        guard current == storedPassword, new.count >= 4 else { return false }
        storedPassword = new
        UserDefaults.standard.set(true, forKey: passwordChangedKey)
        return true
    }
}
