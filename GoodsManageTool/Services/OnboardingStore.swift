import Foundation

enum OnboardingStore {
    private static let completedKey = "hasCompletedOnboarding"
    private static let legacySeededKey = "hasSeededInitialProducts"

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedKey) }
    }

    static func complete(withSampleExperience: Bool) {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(withSampleExperience, forKey: "onboardingChoseSample")
    }

    static var choseSampleExperience: Bool {
        UserDefaults.standard.bool(forKey: "onboardingChoseSample")
    }

    /// Upgrades installs that already received silent seed data before onboarding existed.
    static func migrateLegacyInstallIfNeeded() {
        guard !hasCompletedOnboarding else { return }
        guard UserDefaults.standard.bool(forKey: legacySeededKey) else { return }
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "onboardingChoseSample")
    }
}
