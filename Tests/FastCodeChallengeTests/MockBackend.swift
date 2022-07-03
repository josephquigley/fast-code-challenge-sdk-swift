import Foundation
@testable import FastCodeChallenge

struct MockBackend: FastCodeBackend {
    struct MockBackendTask: FastCodeBackendTask {
        func resume() { /* Intentionally Blank */ }
    }
    
    struct MockBackendResult {
        let jsonResponse: String
        var error: Error? = nil
        var statusCode: Int = 200
        var headerFields = [String: String]()
        var httpVersion = "2.0"
    }
    
    enum MockBackendError: Error {
        case missingMockDataForRequest
    }
    
    let responses: [URLRequest: MockBackendResult]
    
    func fastCodeTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> FastCodeChallenge.FastCodeBackendTask {
        if let result = responses.first(where: { $0.key == request })?.value {
            let urlResponse = HTTPURLResponse(url: request.url!,
                                              statusCode: result.statusCode,
                                              httpVersion: result.httpVersion,
                                              headerFields: result.headerFields)
            completionHandler(result.jsonResponse.data(using: .utf8),
                              urlResponse,
                              result.error)
        } else {
            let urlResponse = HTTPURLResponse(url: request.url!,
                                              statusCode: 501,
                                              httpVersion: "2.0",
                                              headerFields: [:])
            completionHandler(nil,
                              urlResponse,
                              MockBackendError.missingMockDataForRequest)
            
        }
        
        return MockBackendTask()
    }
}

extension MockBackend {
    init(responses: [URLRequest: String]) {
        var mappedResponses = [URLRequest: MockBackendResult]()
        responses.forEach {
            mappedResponses[$0.key] = MockBackendResult(jsonResponse: $0.value)
        }
        
        self.responses = mappedResponses
    }
}
