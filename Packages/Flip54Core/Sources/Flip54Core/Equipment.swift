public struct Equipment: Codable, Hashable, Sendable {
    public var hasWeights: Bool
    public var hasPullUpBar: Bool
    public var hasYogaMat: Bool

    public init(hasWeights: Bool, hasPullUpBar: Bool, hasYogaMat: Bool) {
        self.hasWeights = hasWeights
        self.hasPullUpBar = hasPullUpBar
        self.hasYogaMat = hasYogaMat
    }

    public static let bodyWeightOnly = Equipment(hasWeights: false, hasPullUpBar: false, hasYogaMat: false)
    public static let fullKit        = Equipment(hasWeights: true,  hasPullUpBar: true,  hasYogaMat: true)
    public static let barOnly        = Equipment(hasWeights: false, hasPullUpBar: true,  hasYogaMat: false)
    public static let weightsOnly    = Equipment(hasWeights: true,  hasPullUpBar: false, hasYogaMat: false)
}
