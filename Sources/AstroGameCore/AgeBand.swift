import Foundation

public enum AgeBand: String, CaseIterable, Codable, Identifiable, Sendable {
    case ages4To6
    case ages7To9
    case ages10To12

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .ages4To6:
            "Ages 4–6"
        case .ages7To9:
            "Ages 7–9"
        case .ages10To12:
            "Ages 10–12"
        }
    }

    public var modeName: String {
        switch self {
        case .ages4To6:
            "Junior Explorer"
        case .ages7To9:
            "Space Explorer"
        case .ages10To12:
            "Mission Scientist"
        }
    }
}
