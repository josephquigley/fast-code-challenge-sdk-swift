import Foundation

public protocol FastCodeBackend {
    func fastCodeTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> FastCodeBackendTask
}

public protocol FastCodeBackendTask {
    func resume()
}

public enum FastCodeError: LocalizedError {
    case unknown
    case invalidToken
    case unknownWithMessage(String)
    
    public var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        case .unknownWithMessage(let message):
            return message
        case .invalidToken:
            return "Invalid token"
        }
    }
    
    public var failureReason: String? {
        // This won't be useful once more error cases are added
        errorDescription
    }
}

extension URLSession: FastCodeBackend {
    public func fastCodeTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> FastCodeBackendTask {
        dataTask(with: request, completionHandler: completionHandler)
    }
}
extension URLSessionDataTask: FastCodeBackendTask { }
