//
//  GeneratorTests.swift
//  WeaverCodeGenTests
//
//  Created by Théophane Rupin on 3/4/18.
//

import Foundation
import XCTest
import SourceKittenFramework
import PathKit

@testable import WeaverCodeGen

final class GeneratorTests: XCTestCase {
    
    private let templatePath = Path(#file).parent() + Path("../../Resources/dependency_resolver.stencil")
    
    func test_generator_should_return_nil_when_no_annotation_is_detected() {
        
        do {
            let file = File(contents: """
final class MyService {
  let dependencies: DependencyResolver

  init(_ dependencies: DependencyResolver) {
    self.dependencies = dependencies
  }
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            let graph = try Linker(syntaxTrees: [ast]).graph
            
            let generator = try Generator(graph: graph, template: templatePath)
            XCTAssertNil(try generator.generate().first)
            
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func test_generator_should_generate_a_valid_swift_code_when_an_empty_type_gets_registered() {
        
        do {
            let file = File(contents: """
final class Logger {
    func log(_ message: String) { print(message) }

    // weaver: logEngine = LogEngine
}

final class Manager {
    // weaver: logger = Logger
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            let graph = try Linker(syntaxTrees: [ast]).graph
            
            let generator = try Generator(graph: graph, template: templatePath)
            let (_ , actual) = try generator.generate().first!
            
            let expected = """
/// This file is generated by Weaver 0.10.0
/// DO NOT EDIT!
// MARK: - Logger
protocol LoggerDependencyResolver {
    var logEngine: LogEngine { get }
}
final class LoggerDependencyContainer: LoggerDependencyResolver {
    private var _logEngine: LogEngine?
    var logEngine: LogEngine {
        if let value = _logEngine { return value }
        let value = LogEngine()
        _logEngine = value
        return value
    }
    init() {
        _ = logEngine
    }
}
// MARK: - Manager
protocol ManagerDependencyResolver {
    var logger: Logger { get }
}
final class ManagerDependencyContainer: ManagerDependencyResolver {
    private var _logger: Logger?
    var logger: Logger {
        if let value = _logger { return value }
        let value = Logger()
        _logger = value
        return value
    }
    init() {
        _ = logger
    }
}
extension ManagerDependencyContainer: LoggerInputDependencyResolver {}
"""
            
            XCTAssertEqual(actual!, expected)
            exportDiff(actual: actual!, expected: expected)

        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func test_generator_should_generate_a_valid_swift_code_when_an_isolated_type_gets_registered() {
        
        do {
            let file = File(contents: """
final class PersonManager: PersonManaging {

    // weaver: self.isIsolated = true

    // weaver: logger = Logger
    
    // weaver: movieAPI <- APIProtocol
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            let graph = try Linker(syntaxTrees: [ast]).graph
            
            let generator = try Generator(graph: graph, template: templatePath)
            let (_ , actual) = try generator.generate().first!
            
            let expected = """
/// This file is generated by Weaver 0.10.0
/// DO NOT EDIT!
// MARK: - PersonManager
protocol PersonManagerInputDependencyResolver {
    var movieAPI: APIProtocol { get }
}
protocol PersonManagerDependencyResolver {
    var movieAPI: APIProtocol { get }
    var logger: Logger { get }
}
final class PersonManagerDependencyContainer: PersonManagerDependencyResolver {
    let movieAPI: APIProtocol
    private var _logger: Logger?
    var logger: Logger {
        if let value = _logger { return value }
        let value = Logger()
        _logger = value
        return value
    }
    init(injecting dependencies: PersonManagerInputDependencyResolver) {
        movieAPI = dependencies.movieAPI
        _ = logger
    }
}
protocol PersonManagerDependencyInjectable {
    init(injecting dependencies: PersonManagerDependencyResolver)
}
"""
            
            XCTAssertEqual(actual!, expected)
            exportDiff(actual: actual!, expected: expected)

        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func test_generator_should_generate_a_valid_swift_code_with_a_customRef() {
        
        do {
            let file = File(contents: """
final class PersonManager: PersonManaging {
    // weaver: movieAPI = MovieAPI <- APIProtocol
    // weaver: movieAPI.customRef = true
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            let graph = try Linker(syntaxTrees: [ast]).graph
            
            let generator = try Generator(graph: graph, template: templatePath)
            let (_ , actual) = try generator.generate().first!
            
            let expected = """
/// This file is generated by Weaver 0.10.0
/// DO NOT EDIT!
// MARK: - PersonManager
protocol PersonManagerDependencyResolver {
    var movieAPI: APIProtocol { get }
    func movieAPICustomRef() -> APIProtocol
}
final class PersonManagerDependencyContainer: PersonManagerDependencyResolver {
    private var _movieAPI: APIProtocol?
    var movieAPI: APIProtocol {
        if let value = _movieAPI { return value }
        let value = movieAPICustomRef()
        _movieAPI = value
        return value
    }
    init() {
        _ = movieAPI
    }
}
"""
            
            XCTAssertEqual(actual!, expected)
            exportDiff(actual: actual!, expected: expected)

        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func test_generator_should_generate_a_valid_swift_code_with_a_customRef_taking_parameters() {
        
        do {
            let file = File(contents: """
final class MovieAPI {
    // weaver: host <= String
}

final class PersonManager: PersonManaging {
    // weaver: movieAPI = MovieAPI <- APIProtocol
    // weaver: movieAPI.customRef = true
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            let graph = try Linker(syntaxTrees: [ast]).graph
            
            let generator = try Generator(graph: graph, template: templatePath)
            let (_ , actual) = try generator.generate().first!
            
            let expected = """
/// This file is generated by Weaver 0.10.0
/// DO NOT EDIT!
// MARK: - MovieAPI
protocol MovieAPIDependencyResolver {
    var host: String { get }
}
final class MovieAPIDependencyContainer: MovieAPIDependencyResolver {
    let host: String
    init(host: String) {
        self.host = host
    }
}
protocol MovieAPIDependencyInjectable {
    init(injecting dependencies: MovieAPIDependencyResolver)
}
// MARK: - PersonManager
protocol PersonManagerDependencyResolver {
    var movieAPI: APIProtocol { get }
    func movieAPICustomRef() -> APIProtocol
}
final class PersonManagerDependencyContainer: PersonManagerDependencyResolver {
    private var _movieAPI: APIProtocol?
    func movieAPI(host: String) -> APIProtocol {
        if let value = _movieAPI { return value }
        let value = movieAPICustomRef()
        _movieAPI = value
        return value
    }
    init() {
        _ = movieAPI(host: host)
    }
}
extension PersonManagerDependencyContainer: MovieAPIInputDependencyResolver {}
"""
            
            XCTAssertEqual(actual!, expected)
            exportDiff(actual: actual!, expected: expected)

        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func test_generator_should_generate_a_valid_swift_code_with_embedded_injectable_types() {
        
        do {
            let file = File(contents: """
final class MyService {
  // weaver: session = Session

  final class MyEmbeddedService {

    // weaver: session = Session? <- SessionProtocol?
    // weaver: session.scope = .container
  }
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            let graph = try Linker(syntaxTrees: [ast]).graph
            
            let generator = try Generator(graph: graph, template: templatePath)
            let (_ , actual) = try generator.generate().first!
            
            let expected = """
/// This file is generated by Weaver 0.10.0
/// DO NOT EDIT!
// MARK: - MyService
protocol MyServiceDependencyResolver {
    var session: Session { get }
}
final class MyServiceDependencyContainer: MyServiceDependencyResolver {
    private var _session: Session?
    var session: Session {
        if let value = _session { return value }
        let value = Session()
        _session = value
        return value
    }
    init() {
        _ = session
    }
}
// MARK: - MyEmbeddedService
protocol MyEmbeddedServiceDependencyResolver {
    var session: SessionProtocol? { get }
}
final class MyEmbeddedServiceDependencyContainer: MyEmbeddedServiceDependencyResolver {
    private var _session: SessionProtocol??
    var session: SessionProtocol? {
        if let value = _session { return value }
        let value = Session?()
        _session = value
        return value
    }
    init() {
        _ = session
    }
}
"""
            
            XCTAssertEqual(actual!, expected)
            exportDiff(actual: actual!, expected: expected)

        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func test_generator_should_generate_a_valid_swift_code_with_a_public_injectableType() {
        
        do {
            let file = File(contents: """
public final class API {
  // weaver: session = Session
  // weaver: logger <- Logger
  // weaver: host <= String
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            let graph = try Linker(syntaxTrees: [ast]).graph
            
            let generator = try Generator(graph: graph, template: templatePath)

            let (_ , actual) = try generator.generate().first!
            
            let expected = """
/// This file is generated by Weaver 0.10.0
/// DO NOT EDIT!
// MARK: - API
protocol APIInputDependencyResolver {
    var logger: Logger { get }
}
protocol APIDependencyResolver {
    var host: String { get }
    var logger: Logger { get }
    var session: Session { get }
}
final class APIDependencyContainer: APIDependencyResolver {
    let host: String
    let logger: Logger
    private var _session: Session?
    var session: Session {
        if let value = _session { return value }
        let value = Session()
        _session = value
        return value
    }
    init(injecting dependencies: APIInputDependencyResolver, host: String) {
        self.host = host
        logger = dependencies.logger
        _ = session
    }
}
protocol APIDependencyInjectable {
    init(injecting dependencies: APIDependencyResolver)
}
final class APIShimDependencyContainer: APIInputDependencyResolver {
    let logger: Logger
    init(logger: Logger) {
        self.logger = logger
    }
}
extension API {
    public convenience init(logger: Logger, host: String) {
        let shim = APIShimDependencyContainer(logger: logger)
        let dependencies = APIDependencyContainer(injecting: shim, host: host)
        self.init(injecting: dependencies)
    }
}
"""
            
            XCTAssertEqual(actual!, expected)
            exportDiff(actual: actual!, expected: expected)

        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func test_generator_should_generate_a_valid_swift_code_with_ignored_types() {
        
        do {
            let file = File(contents: """
final class API: APIProtocol {
    // weaver: parameter <= UInt
}

class AnotherService {
    // This class is ignored
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            let graph = try Linker(syntaxTrees: [ast]).graph
            
            let generator = try Generator(graph: graph, template: templatePath)
            let (_ , actual) = try generator.generate().first!
            
            let expected = """
/// This file is generated by Weaver 0.10.0
/// DO NOT EDIT!
// MARK: - API
protocol APIDependencyResolver {
    var parameter: UInt { get }
}
final class APIDependencyContainer: APIDependencyResolver {
    let parameter: UInt
    init(parameter: UInt) {
        self.parameter = parameter
    }
}
protocol APIDependencyInjectable {
    init(injecting dependencies: APIDependencyResolver)
}
"""
            XCTAssertEqual(actual!, expected)
            exportDiff(actual: actual!, expected: expected)
            
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func test_generator_should_generate_a_valid_swift_code_with_internal_type_with_one_parameter_being_registered_in_a_public_type() {
        
        do {
            let file = File(contents: """
final class Logger {
    // weaver: domain <= String
}
public final class MovieManager {
    // weaver: logger = Logger
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            let graph = try Linker(syntaxTrees: [ast]).graph
            
            let generator = try Generator(graph: graph, template: templatePath)
            let (_ , actual) = try generator.generate().first!
            
            let expected = """
/// This file is generated by Weaver 0.10.0
/// DO NOT EDIT!
// MARK: - Logger
protocol LoggerDependencyResolver {
    var domain: String { get }
}
final class LoggerDependencyContainer: LoggerDependencyResolver {
    let domain: String
    init(domain: String) {
        self.domain = domain
    }
}
protocol LoggerDependencyInjectable {
    init(injecting dependencies: LoggerDependencyResolver)
}
// MARK: - MovieManager
protocol MovieManagerDependencyResolver {
    func logger(domain: String) -> Logger
}
final class MovieManagerDependencyContainer: MovieManagerDependencyResolver {
    private var _logger: Logger?
    func logger(domain: String) -> Logger {
        if let value = _logger { return value }
        let dependencies = LoggerDependencyContainer(injecting: self, domain: domain)
        let value = Logger(injecting: dependencies)
        _logger = value
        return value
    }
    init() {
        _ = logger(domain: domain)
    }
}
extension MovieManagerDependencyContainer: LoggerInputDependencyResolver {}
extension MovieManager {
    public convenience init() {
        let dependencies = MovieManagerDependencyContainer()
        self.init(injecting: dependencies)
    }
}
"""
            
            XCTAssertEqual(actual!, expected)
            exportDiff(actual: actual!, expected: expected)
            
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func test_generator_should_generate_a_valid_swift_code_with_type_registering_a_generic_dependency() {
        
        do {
            let file = File(contents: """
final class MovieManager {
    // weaver: logger = Logger<String>
}
final class Logger<T> {
    // weaver: domain <= String
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            let graph = try Linker(syntaxTrees: [ast]).graph
            
            let generator = try Generator(graph: graph, template: templatePath)
            let (_ , actual) = try generator.generate().first!
            
            let expected = """
/// This file is generated by Weaver 0.10.0
/// DO NOT EDIT!
// MARK: - Logger
protocol LoggerDependencyResolver {
    var domain: String { get }
}
final class LoggerDependencyContainer<T>: LoggerDependencyResolver {
    let domain: String
    init(domain: String) {
        self.domain = domain
    }
}
protocol LoggerDependencyInjectable {
    associatedtype T
    init(injecting dependencies: LoggerDependencyContainer<T>)
}
// MARK: - MovieManager
protocol MovieManagerDependencyResolver {
    func logger(domain: String) -> Logger<String>
}
final class MovieManagerDependencyContainer: MovieManagerDependencyResolver {
    private var _logger: Logger<String>?
    func logger(domain: String) -> Logger<String> {
        if let value = _logger { return value }
        let dependencies = LoggerDependencyContainer(injecting: self, domain: domain)
        let value = Logger<String>(injecting: dependencies)
        _logger = value
        return value
    }
    init() {
        _ = logger(domain: domain)
    }
}
extension MovieManagerDependencyContainer: LoggerInputDependencyResolver {}
"""
            
            XCTAssertEqual(actual!, expected)
            exportDiff(actual: actual!, expected: expected)
            
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func test_generator_should_generate_a_valid_swift_code_with_injectable_class_with_indirect_references() {
        
        do {
            let file = File(contents: """
final class AppDelegate {
    // weaver: movieManager = MovieManager
    // weaver: movieManager.scope = .container

    // weaver: homeViewController = HomeViewController
}

final class HomeViewController {
    // weaver: movieViewController = MovieViewController
    // weaver: movieViewController.scope = .transient
}

final class MovieViewController {
    // weaver: reviewViewController = ReviewViewController
    // weaver: reviewViewController.scope = .transient
}

final class ReviewViewController {
    // weaver: movieManager <- MovieManager
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let ast = try parser.parse()
            let graph = try Linker(syntaxTrees: [ast]).graph
            
            let generator = try Generator(graph: graph, template: templatePath)
            let (_ , actual) = try generator.generate().first!
            
            let expected = """
/// This file is generated by Weaver 0.10.0
/// DO NOT EDIT!
// MARK: - HomeViewController
protocol HomeViewControllerInputDependencyResolver {
    var movieManager: MovieManager { get }
}
protocol HomeViewControllerDependencyResolver {
    var movieManager: MovieManager { get }
    var movieViewController: MovieViewController { get }
}
final class HomeViewControllerDependencyContainer: HomeViewControllerDependencyResolver {
    let movieManager: MovieManager
    var movieViewController: MovieViewController {
        let value = MovieViewController()
        return value
    }
    init(injecting dependencies: HomeViewControllerInputDependencyResolver) {
        movieManager = dependencies.movieManager
    }
}
extension HomeViewControllerDependencyContainer: MovieViewControllerInputDependencyResolver {}
// MARK: - MovieViewController
protocol MovieViewControllerInputDependencyResolver {
    var movieManager: MovieManager { get }
}
protocol MovieViewControllerDependencyResolver {
    var movieManager: MovieManager { get }
    var reviewViewController: ReviewViewController { get }
}
final class MovieViewControllerDependencyContainer: MovieViewControllerDependencyResolver {
    let movieManager: MovieManager
    var reviewViewController: ReviewViewController {
        let dependencies = ReviewViewControllerDependencyContainer(injecting: self)
        let value = ReviewViewController(injecting: dependencies)
        return value
    }
    init(injecting dependencies: MovieViewControllerInputDependencyResolver) {
        movieManager = dependencies.movieManager
    }
}
extension MovieViewControllerDependencyContainer: ReviewViewControllerInputDependencyResolver {}
// MARK: - ReviewViewController
protocol ReviewViewControllerInputDependencyResolver {
    var movieManager: MovieManager { get }
}
protocol ReviewViewControllerDependencyResolver {
    var movieManager: MovieManager { get }
}
final class ReviewViewControllerDependencyContainer: ReviewViewControllerDependencyResolver {
    let movieManager: MovieManager
    init(injecting dependencies: ReviewViewControllerInputDependencyResolver) {
        movieManager = dependencies.movieManager
    }
}
protocol ReviewViewControllerDependencyInjectable {
    init(injecting dependencies: ReviewViewControllerDependencyResolver)
}
// MARK: - AppDelegate
protocol AppDelegateDependencyResolver {
    var movieManager: MovieManager { get }
    var homeViewController: HomeViewController { get }
}
final class AppDelegateDependencyContainer: AppDelegateDependencyResolver {
    private var _movieManager: MovieManager?
    var movieManager: MovieManager {
        if let value = _movieManager { return value }
        let value = MovieManager()
        _movieManager = value
        return value
    }
    private var _homeViewController: HomeViewController?
    var homeViewController: HomeViewController {
        if let value = _homeViewController { return value }
        let value = HomeViewController()
        _homeViewController = value
        return value
    }
    init() {
        _ = movieManager
        _ = homeViewController
    }
}
extension AppDelegateDependencyContainer: HomeViewControllerInputDependencyResolver {}
"""
            
            XCTAssertEqual(actual!, expected)
            exportDiff(actual: actual!, expected: expected)
            
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}

// MARK: - Diff Tools

private extension GeneratorTests {
    
    func exportDiff(actual: String, expected: String, _ function: StringLiteralType = #function) {
        
        guard actual != expected else { return }

        let dirPath = "/tmp/weaver_tests/\(GeneratorTests.self)"
        let function = function.split(separator: "(").first ?? ""
        let actualFilePath = "\(dirPath)/\(function)_actual.swift"
        let expectedFilePath = "\(dirPath)/\(function)_expected.swift"

        guard let actualData = actual.data(using: .utf8),
              let expectedData = expected.data(using: .utf8) else {
            XCTFail("Could not convert string to utf8")
            return
        }

        let fileManager = FileManager.default

        do {
            try fileManager.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
            
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        fileManager.createFile(atPath: actualFilePath, contents: actualData, attributes: nil)
        fileManager.createFile(atPath: expectedFilePath, contents: expectedData, attributes: nil)

        print("Execute the following to check the diffs:")
        print("diff \(actualFilePath) \(expectedFilePath)")
    }
}
