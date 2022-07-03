import Foundation

public struct SubmissionResult: Decodable, CustomStringConvertible {
    public let correct: Bool
    public let seconds: Double?
    
    public var description: String {
        let correctStr = "correct: \(correct)"
        
        if let seconds = seconds {
            return "\(correctStr)\nseconds: \(seconds)"
        } else {
            return correctStr
        }
    }
}
