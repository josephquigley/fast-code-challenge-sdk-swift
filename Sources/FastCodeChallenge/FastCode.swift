import Foundation

/// FastCode.rocks API interface for fetching problem data sets and submitting answers
public struct FastCode {
    public enum HTTPMethod {
        case get
        case post(Data)
    }
    
    public typealias FastCodeResult = (Data?, Error?) -> Void
    public let token: String
    public let backend: FastCodeBackend
    
    private static let baseUrl = URL(string: "https://fastcode.rocks/fast/data")!
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    /// FastCode Initializer
    /// - Parameter token: API Token to identify requests (Can be found on the FastCode.rocks profile page)
    public init(token: String, backend: FastCodeBackend = URLSession.shared) {
        self.token = token
        self.backend = backend
    }
    
    
    /// Fetches a problem data set from the RastCode.rocks server with the provided identifier.
    ///
    /// It is up to the implementer of the `dataSetResult` block to decode the data to the appropriate type as defined by the problem instructions.
    ///
    /// - Parameters:
    ///   - problemId: The problem data set id.
    ///   - perform: A code block containing the raw problem set data as a `Data` object and an `Error`. If an error is returned, the problem set data will be nil. If a data set was returned the error will be nil.
    public func getDataSet(for problemId: String,
                           dataSetResult: @escaping FastCodeResult) {
        performRequest(urlRequest(forProblemId: problemId, method: .get), task: dataSetResult)
    }
    
    /// Submit an answer to the FastCode.rocks server for scoring.
    ///
    /// Each FastCode challenge expects an answer type that is specific to that particular problem (eg: String, Int, etc). Ensure that the correct submission type is used or else the server will reject the submission with a "Bad Request" result.
    ///
    /// - Parameters:
    ///   - answer: A `Submission` object with the computed answer for a given problem data set.
    ///   - problemId: The problem data set id.
    ///   - result: A block that is provided a `SubmissionResult` and `Error` tuple from the FastCode server with the the answer correctness and (if correct) the computation duration to solve for the correct answer. If an error is returned, the submission result will be nil. If a submission result is returned, the error will be nil.
    public func submit<T: Encodable>(answer: Submission<T>,
                                     for problemId: String,
                                     result: @escaping (SubmissionResult?, Error?) -> Void) {
        do {
            let request = urlRequest(forProblemId: problemId, method: .post(try encoder.encode(answer)))
            performRequest(request, task: { data, error in
                do {
                    guard let data = data else {
                        result(nil, error)
                        return
                    }
                    result(try decoder.decode(SubmissionResult.self, from: data), nil)
                } catch let error {
                    result(nil, error)
                }
            })
        } catch let error {
            // End this challenge's timer with a nil submission
            performRequest(urlRequest(forProblemId: problemId, method: .post(Data())), task: { _, _ in
                result(nil, error)
            })
        }
    }
    
    
    /// Fetches the problem data set and automatically submits the answer provided by the `problemTask` block.
    ///
    /// Each FastCode challenge expects an answer type that is specific to that particular problem (eg: `String`, `Int`, etc). Ensure that the correct submission type is used or else the server will reject the submission with a "Bad Request" result.
    ///
    /// It is up to the implementer of the `problemTask` block to decode the data to the appropriate type as defined by the problem instructions.
    ///
    /// - Parameters:
    ///   - problemId: The problem data set id
    ///   - onError: Error callback (eg, wrong submission data type, network error)
    ///   - onSuccess: `SubmissionResult` with a flag indicating the answer correctness and (if correct) the computation duration to solve for the correct answer.
    ///   - problemTask: The code block to be called which takes the data set and returns the computed answer.
    public func solve<T: Encodable>(problemId: String,
                                  onError: @escaping (Error) -> Void,
                                  onSuccess: @escaping (SubmissionResult) -> Void,
                                  problemTask: @escaping (Data) -> T) {
        getDataSet(for: problemId) { data, error in
            guard let data = data else {
                if let error = error {
                    onError(error)
                } else {
                    onError(FastCodeError.unknown)
                }
                return
            }

            submit(answer: Submission(answer: problemTask(data)),
                   for: problemId) { result, error in
                guard let result = result else {
                    if let error = error {
                        onError(error)
                    } else {
                        onError(FastCodeError.unknown)
                    }
                    return
                }
                onSuccess(result)
            }
        }
    }
    
    internal func performRequest(_ urlRequest: URLRequest, task: @escaping FastCodeResult) {
        let urlTask = backend.fastCodeTask(with: urlRequest) { data, response, error in
            if let error = error {
                task(nil, error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                    let data = data else {
                return
            }
            
            task(data, nil)
        }
        urlTask.resume()
    }
    
    internal func urlRequest(forProblemId problemId: String, method: HTTPMethod) -> URLRequest {
        Self.urlRequest(forProblemId: problemId, method: method, token: token)
    }
    
    internal static func urlRequest(forProblemId problemId: String, method: HTTPMethod, token: String) -> URLRequest {
        let url = baseUrl.appendingPathComponent(problemId)
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        switch method {
        case .get:
            request.httpMethod = "GET"
        case .post(let data):
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = data
        }
        
        return request
    }
}
