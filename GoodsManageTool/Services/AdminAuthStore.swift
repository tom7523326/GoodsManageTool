import CryptoKit
import Foundation
import Observation

@Observable
final class AdminAuthStore {
    static let defaultPassword = "111111"
    static let sessionDuration: TimeInterval = 5 * 60
    private static let maxFailuresBeforeLockout = 5
    private static let lockoutBaseSeconds: TimeInterval = 30

    private let passwordHashKey = "adminPasswordHash"
    private let legacyPasswordKey = "adminPassword"
    private let passwordChangedKey = "adminPasswordHasChanged"
    private let failureCountKey = "adminAuthFailureCount"
    private let lockoutUntilKey = "adminAuthLockoutUntil"
    private var sessionExpiresAt: Date?

    var isUnlocked: Bool {
        guard let sessionExpiresAt else { return false }
        return Date() < sessionExpiresAt
    }

    var shouldShowDefaultPasswordHint: Bool {
        !UserDefaults.standard.bool(forKey: passwordChangedKey)
    }

    var lockoutRemainingSeconds: Int? {
        _ = lockoutRefreshToken
        guard let lockoutUntil = lockoutUntil, Date() < lockoutUntil else { return nil }
        return max(Int(lockoutUntil.timeIntervalSinceNow.rounded(.up)), 1)
    }

    private(set) var lockoutRefreshToken = 0

    func refreshLockoutIfNeeded() {
        if let lockoutUntil, Date() >= lockoutUntil {
            self.lockoutUntil = nil
        }
        lockoutRefreshToken += 1
    }

    @discardableResult
    func unlock(with input: String) -> Bool {
        if let lockoutUntil = lockoutUntil, Date() < lockoutUntil {
            return false
        }

        guard matchesPassword(input) else {
            registerFailure()
            return false
        }

        resetFailures()
        sessionExpiresAt = Date().addingTimeInterval(Self.sessionDuration)
        return true
    }

    func lock() {
        sessionExpiresAt = nil
    }

    func invalidateIfExpired() {
        guard let sessionExpiresAt, Date() >= sessionExpiresAt else { return }
        self.sessionExpiresAt = nil
    }

    @discardableResult
    func changePassword(current: String, new: String) -> Bool {
        guard matchesPassword(current), new.count >= 4 else { return false }
        storedPasswordHash = Self.hash(new)
        UserDefaults.standard.set(true, forKey: passwordChangedKey)
        UserDefaults.standard.removeObject(forKey: legacyPasswordKey)
        return true
    }

    private var storedPasswordHash: String {
        get {
            if let hash = UserDefaults.standard.string(forKey: passwordHashKey) {
                return hash
            }
            if let legacy = UserDefaults.standard.string(forKey: legacyPasswordKey) {
                return Self.hash(legacy)
            }
            return Self.hash(Self.defaultPassword)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: passwordHashKey)
        }
    }

    private var failureCount: Int {
        get { UserDefaults.standard.integer(forKey: failureCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: failureCountKey) }
    }

    private var lockoutUntil: Date? {
        get {
            let timestamp = UserDefaults.standard.double(forKey: lockoutUntilKey)
            guard timestamp > 0 else { return nil }
            return Date(timeIntervalSince1970: timestamp)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: lockoutUntilKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lockoutUntilKey)
            }
        }
    }

    private func matchesPassword(_ input: String) -> Bool {
        if let legacy = UserDefaults.standard.string(forKey: legacyPasswordKey), legacy == input {
            storedPasswordHash = Self.hash(input)
            UserDefaults.standard.removeObject(forKey: legacyPasswordKey)
            return true
        }
        return Self.hash(input) == storedPasswordHash
    }

    private func registerFailure() {
        failureCount += 1
        guard failureCount >= Self.maxFailuresBeforeLockout else { return }
        let multiplier = Double(failureCount - Self.maxFailuresBeforeLockout + 1)
        lockoutUntil = Date().addingTimeInterval(Self.lockoutBaseSeconds * multiplier)
    }

    private func resetFailures() {
        failureCount = 0
        lockoutUntil = nil
    }

    private static func hash(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
