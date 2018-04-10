//
//  MovieAPITests.swift
//  SampleTests
//
//  Created by Théophane Rupin on 4/9/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation
import XCTest

@testable import Sample

final class MovieAPITests: XCTestCase {

    var movieAPIDependencyResolverMock: MovieAPIDependencyResolverMock!
    
    var movieAPI: MovieAPI!
    
    override func setUp() {
        super.setUp()
        
        movieAPIDependencyResolverMock = MovieAPIDependencyResolverMock()
        movieAPI = MovieAPI(injecting: movieAPIDependencyResolverMock)
    }
    
    override func tearDown() {
        defer {
            super.tearDown()
        }
        
        movieAPIDependencyResolverMock = nil
        movieAPI = nil
    }
    
    // MARK: - send(request:completion)
    
    func test_sendDataRequest_should_call_urlSession_and_succeed() {

        let responseData = "{}".data(using: .utf8)!
        let responseURL = URL(dataRepresentation: responseData, relativeTo: nil)!
        let responseStub = HTTPURLResponse(url: responseURL, statusCode: 200, httpVersion: nil, headerFields: ["Content-Length": responseData.count.description])!
        let selectResponse = { (request: URLRequest) -> Bool in
            return request.url?.host == "test" && request.url?.path == "/test"
        }
        URLProtocolMock.responseStubs.append((select: selectResponse, stub: .success(responseStub)))
        
        let request = APIRequest<Data>(method: .get, host: "http://test", path: "/test")
        
        let expectation = self.expectation(description: "send")
        
        movieAPI.send(request: request) { result in
            XCTAssertNotNil(URLProtocolMock.requestsSpy.first)

            switch result {
            case .success:
                break
                
            case .failure(let error):
                XCTFail("Unexpected error: \(error)")
            }
            
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}
