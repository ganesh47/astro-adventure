import Foundation

public enum AppleServiceCapability: String, CaseIterable, Sendable {
    case localProgress
    case iCloudSync
    case gameCenterAchievements
    case controllerHaptics

    public var isEnabledInNativeParity: Bool {
        self == .localProgress
    }
}
