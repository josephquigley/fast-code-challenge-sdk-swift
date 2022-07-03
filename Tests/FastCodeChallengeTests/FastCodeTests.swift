import XCTest
import Foundation
@testable import FastCodeChallenge

final class fast_code_challenge_sdk_swiftTests: XCTestCase {
    // Needed to retain scope for closures
    var tasks: [Void] = .init()
    
    func testSuccess() throws {
        let expectation = XCTestExpectation(description: "API call")
        let problemId = "d1e13528-d5d3-494b-beed-be83645f09e4"
        let token = "FooToken"
        let encoder = JSONEncoder()
        let answer = Submission(answer: 14)
        
        
        let backend = MockBackend(responses: [
            FastCode.urlRequest(forProblemId: problemId, method: .get, token: token):
"""
{
    "people": [
        {
            "name": "Joe Someone",
            "age": 56,
            "spouse": null,
            "height": 1.87,
            "weight": 67.5,
            "retired": true,
            "degrees": [ ]
        },
        {
            "name": "Jan Someone",
            "age": 53,
            "spouse": "John Doe",
            "weight": 757.1,
            "retired": false,
            "degrees": [
                "BS",
                "MS",
                "PhD"
            ]
        }
    ]
}
""",
            FastCode.urlRequest(forProblemId: problemId, method: .post(try! encoder.encode(answer)), token: token):
"""
{
"correct" : true,
"seconds" : 0.089371
}
"""
        ])

        let foo = FastCode(token: token, backend: backend)
        
        tasks.append(foo.solve(problemId: problemId,
                  onError: { error in
            XCTFail("Error occurred when success expected:\n\(error.localizedDescription)")
            expectation.fulfill()
        },
                  onSuccess: { result in
            XCTAssertTrue(result.correct, "Incorrect result received when correct expected.")
            expectation.fulfill()
        },
                  problemTask: { data in
            return answer.answer
        }))
        wait(for: [expectation], timeout: 10.0)
        
    }
    
    func testFailure() throws {
        let expectation = XCTestExpectation(description: "API call")
        let problemId = "d1e13528-d5d3-494b-beed-be83645f09e4"
        let token = "FooToken"
        let encoder = JSONEncoder()
        let answer = Submission(answer: false)
        
        
        let backend = MockBackend(responses: [
            FastCode.urlRequest(forProblemId: problemId, method: .get, token: token):
"""
{
    "people": [
        {
            "name": "Joe Someone",
            "age": 56,
            "spouse": null,
            "height": 1.87,
            "weight": 67.5,
            "retired": true,
            "degrees": [ ]
        },
        {
            "name": "Jan Someone",
            "age": 53,
            "spouse": "John Doe",
            "weight": 757.1,
            "retired": false,
            "degrees": [
                "BS",
                "MS",
                "PhD"
            ]
        }
    ]
}
""",
            FastCode.urlRequest(forProblemId: problemId, method: .post(try! encoder.encode(answer)), token: token):
"""
{
"correct" : false
}
"""
        ])

        let foo = FastCode(token: token, backend: backend)
        
        tasks.append(foo.solve(problemId: problemId,
                  onError: { error in
            XCTFail("Error occurred when success expected:\n\(error.localizedDescription)")
            expectation.fulfill()
        },
                  onSuccess: { result in
            XCTAssertFalse(result.correct, "Correct result received when incorrect expected.")
            expectation.fulfill()
        },
                  problemTask: { data in
            return answer.answer
        }))
        wait(for: [expectation], timeout: 10.0)
        
    }
}
