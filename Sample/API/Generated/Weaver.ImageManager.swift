/// This file is generated by Weaver 0.9.12
/// DO NOT EDIT!
import Foundation
import UIKit
import WeaverDI
// MARK: - ImageManager
final class ImageManagerDependencyContainer: DependencyContainer {
    init(parent: Reference<DependencyContainer>? = nil) {
        super.init(parent)
    }
    override func registerDependencies(in store: DependencyStore) {
        store.register(Logger.self, scope: .graph, name: "logger", builder: { (dependencies) in
            return Logger()
        })
        store.register(URLSession.self, scope: .container, name: "urlSession", builder: { (dependencies) in
            return self.urlSessionCustomRef()
        })
    }
}
protocol ImageManagerDependencyResolver {
    var logger: Logger { get }
    var urlSession: URLSession { get }
    var movieAPI: APIProtocol { get }
    func urlSessionCustomRef() -> URLSession
}
extension ImageManagerDependencyContainer: ImageManagerDependencyResolver {
    var logger: Logger {
        return resolve(Logger.self, name: "logger")
    }
    var urlSession: URLSession {
        return resolve(URLSession.self, name: "urlSession")
    }
    var movieAPI: APIProtocol {
        return resolve(APIProtocol.self, name: "movieAPI")
    }
}
extension ImageManager {
    static func makeImageManager(injecting parentDependencies: DependencyContainer) -> ImageManager {
        let dependencies = ImageManagerDependencyContainer(parent: Reference(parentDependencies))
        return ImageManager(injecting: dependencies)
    }
}
protocol ImageManagerDependencyInjectable {
    init(injecting dependencies: ImageManagerDependencyResolver)
}
extension ImageManager: ImageManagerDependencyInjectable {}
// MARK: - ImageManagerShim
final class ImageManagerShimDependencyContainer: DependencyContainer {
    private lazy var internalDependencies: ImageManagerDependencyContainer = {
        return ImageManagerDependencyContainer(parent: Reference(self, type: .weak))
    }()
    let movieAPI: APIProtocol
    init(movieAPI: APIProtocol) {
        self.movieAPI = movieAPI
        super.init()
    }
    override func registerDependencies(in store: DependencyStore) {
        store.register(APIProtocol.self, scope: .weak, name: "movieAPI", builder: { [weak self] _ in
            guard let strongSelf = self else {
                fatalError("Container was released too early. If you see this happen, please file a bug.")
            }
            return strongSelf.movieAPI
        })
    }
}
extension ImageManagerShimDependencyContainer: ImageManagerDependencyResolver {
    var logger: Logger {
        return internalDependencies.resolve(Logger.self, name: "logger")
    }
    var urlSession: URLSession {
        return internalDependencies.resolve(URLSession.self, name: "urlSession")
    }
}
extension ImageManager {
    public convenience init(movieAPI: APIProtocol) {
        let shim = ImageManagerShimDependencyContainer(movieAPI: movieAPI)
        self.init(injecting: shim)
    }
}