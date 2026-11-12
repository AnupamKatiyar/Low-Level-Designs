////
////  CustomNotificationCenter.swift
////  CustomNotification
////
////  Created by Anupam Katiyar on 14/07/26.
////
//
import Foundation


public protocol CustomNotificationProtocol: AnyObject {
    func didReceiveNotification(_ notification: CustomNotificationCenter.NotificationName, _ userInfo: [AnyHashable: Any]?)
}

public class CustomNotificationCenter {
    
    fileprivate let queue = DispatchQueue(label: "com.custom.notification.center", attributes: .concurrent)
    fileprivate var observers = [NotificationName: Set<WeakObserver>]()
    
    public static let shared: CustomNotificationCenter = .init()
    internal init() { }
    
    public func post(_ notification: NotificationName, userInfo: [AnyHashable: Any]? = nil) {
        queue.sync {
            guard let bucket = observers[notification], !bucket.isEmpty else { return }
            
            var aliveObservers = Set<WeakObserver>()
            for weakObserver in bucket {
                if let delegate = weakObserver.delegate?.target {
                    delegate.didReceiveNotification(notification, userInfo)
                    aliveObservers.insert(weakObserver)
                }
                if let observer = weakObserver.selector,
                   let canPerform = observer.target?.responds(to: observer.selector), canPerform {
                    _ = observer.target?.perform(observer.selector, with: userInfo)
                    aliveObservers.insert(weakObserver)
                }
                if let blockNode = weakObserver.blockObj {
                    blockNode.block?(userInfo)
                    aliveObservers.insert(weakObserver)
                }
            }
            
            observers[notification] = aliveObservers.isEmpty ? nil : aliveObservers
        }
        
    }
    
}


public extension CustomNotificationCenter {
    
    func addObserver(_ delegate: CustomNotificationProtocol, forName name: NotificationName) {
        queue.async(flags: .barrier) { [weak self] in
            let delegateNode = DelegateNode(target: delegate)
            let weakObserver = WeakObserver(delegate: delegateNode)
            self?.observers[name, default: []].insert(weakObserver)
        }
    }
    
    func addObserver(observer: AnyObject, selector: Selector, name: NotificationName) {
        
        queue.async(flags: .barrier) { [weak self] in
            let selectorNode = SelectorNode(target: observer, selector: selector)
            let observation = WeakObserver(selector: selectorNode)
            self?.observers[name, default: []].insert(observation)
        }
    }
    
    func addObserver(observer: AnyObject, name: NotificationName, using block: @escaping (([AnyHashable: Any]?) -> Void)) {
        
        queue.async(flags: .barrier) { [weak self] in
            let blockNode = BlockNode(target: observer, block: block)
            let observation = WeakObserver(block: blockNode)
            self?.observers[name, default: []].insert(observation)
        }
    }
    
}

public extension CustomNotificationCenter {
    
    func removeObserver(_ observer: AnyObject, for name: NotificationName) {
        queue.async(flags: .barrier) { [weak self] in
            self?.remove(observer, for: name)
        }
    }
    
    func removeObserver(_ observer: AnyObject) {
        queue.async(flags: .barrier) { [weak self] in
            self?.internalRemove(observer)
        }
    }
    
    func removeAllObservers() {
        queue.async(flags: .barrier) { [weak self] in
            self?.observers.removeAll()
        }
    }
    
    private func internalRemove(_ observer: AnyObject) {
        for name in self.observers.keys {
            remove(observer, for: name)
        }
    }
    
    private func remove(_ observer: AnyObject, for name: NotificationName) {
        let live = self.observers[name]?.filter { !$0.isNull() && !$0.isSame(observer) } ?? []
        self.observers[name] = live.isEmpty ? nil : Set(live)
    }
    
    private func cleanAllDeadObservers() {
        queue.async(flags: .barrier) { [weak self] in
            self?.observers.forEach { name, weakObservers in
                self?.observers[name] = weakObservers.filter { !$0.isNull() }
            }
            self?.observers = self?.observers.filter { $0.value.count > 0 } ?? [:]
        }
    }
    
}

extension CustomNotificationCenter {
    public struct NotificationName: Hashable {
        let rawValue: String
        init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}




//        CustomNotificationCenter.shared.addObserver(self, forName: NotificationName.TestName)
//        CustomNotificationCenter.shared.addObserver(self, forName: NotificationName.TestName)
//
//        CustomNotificationCenter.shared.addObserver(observer: self, name: .TestName) { info in
//            print("closure: ", terminator: "")
//            print(info ?? [:])
//        }
//        CustomNotificationCenter.shared.addObserver(observer: self, selector: #selector(myFunc(_:)), name: .TestName)
//
//        CustomNotificationCenter.shared.removeObserver(self)





