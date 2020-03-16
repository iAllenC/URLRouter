//
//  Router.swift
//  Router
//
//  Created by iAllenC on 2020/3/12.
//  Copyright © 2020 iAllenC. All rights reserved.
//

import UIKit

public typealias RouteParameter = [String: Any?]
public typealias RouteCompletion = (RouteParameter) -> Void

public protocol Router {
    
    //required
    init()

    //required
    static var module: String { get }
            
    //optional
    static func subRouterType(for module: String) -> Router.Type?

    //required
    func route(_ url: URLConvertible, parameter: RouteParameter?, completion: RouteCompletion?)
    
    //optional
    func fetch(_ url: URLConvertible, parameter: RouteParameter?, completion: RouteCompletion?) -> Any?
    
}

extension Router {
        
    public static func subRouterType(for module: String) -> Router.Type? { nil }

    //find the appropriate router for url
    public static func subRouterType(from url: URLConvertible) -> Router.Type? {
        guard let url = url.asURL, let host = url.host, url.path.count > 0 else { return nil }
        //the first of url.pathComponents is a "/", so we just ignore it
        let pathComponents = [String](url.pathComponents[1..<url.pathComponents.count])
        if host == Self.module {
            guard let targetModule = pathComponents.first else { return nil }
            return subRouterType(for: targetModule)
        } else {
            if let matchIndex = pathComponents.firstIndex(of: Self.module), matchIndex < pathComponents.count - 1 {
                let targetModule = pathComponents[pathComponents.index(after: matchIndex)]
                return subRouterType(for: targetModule)
            } else {
                return nil
            }
        }
    }


    public func fetch(_ url: URLConvertible, parameter: RouteParameter?, completion: RouteCompletion?) -> Any? { nil }
    
}

private struct EmptyRouter: Router {
            
    static var module: String { "Router.Empty" }
 
    func route(_ url: URLConvertible, parameter: RouteParameter?, completion: RouteCompletion?) {
        completion?(["result":false])
    }

    func fetch(_ url: URLConvertible, parameter: RouteParameter?, completion: RouteCompletion?) -> Any? {
        completion?(["result":false])
        return nil
    }
}

public class RouterFactory {
    
    public static let shared: RouterFactory = RouterFactory()
        
    private var routerTypes: [String: Router.Type] = [:]
    
    public func router(for url: URLConvertible) -> Router {
        if let module = url.asURL?.host, var routerType = routerTypes[module] {
            while let subType = routerType.subRouterType(from: url) {
                routerType = subType
            }
            return routerType.init()
        } else {
            return EmptyRouter()
        }
    }
        
    public func register(_ routerType: Router.Type) {
        routerTypes[routerType.module] = routerType
    }
    
}

// The convenience functions to register a router type

public func Register(_ routerType: Router.Type) {
    RouterFactory.shared.register(routerType)
}

public func Register(_ routerTypes: [Router.Type]) {
    routerTypes.forEach { Register($0) }
}


// The convenience functions to route or fetch a url

public func Route(_ url: URLConvertible, parameter: RouteParameter? = nil, completion: RouteCompletion? = nil) {
    RouterFactory.shared.router(for: url).route(url, parameter: parameter, completion: completion)
}

public func Fetch(_ url: URLConvertible, parameter: RouteParameter? = nil, completion: RouteCompletion? = nil) -> Any? {
    RouterFactory.shared.router(for: url).fetch(url, parameter: parameter, completion: completion)
}
