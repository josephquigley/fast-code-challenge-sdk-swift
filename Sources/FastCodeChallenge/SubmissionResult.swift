import Foundation

public struct SubmissionResult: Decodable {
    public let correct: Bool
    public let seconds: Double?
}
