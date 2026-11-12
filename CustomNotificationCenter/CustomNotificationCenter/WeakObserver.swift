//
//  WeakObserver.swift
//  CustomNotification
//
//  Created by Anupam Katiyar on 16/07/26.
//

import ObjectiveC

class WeakObserver: Hashable {
    private(set) var delegate: DelegateNode?
    private(set) var selector: SelectorNode?
    private(set) var blockObj: BlockNode?
    
    private let id: ObjectIdentifier

    init(delegate: DelegateNode) {
        self.delegate = delegate
        self.id = ObjectIdentifier(delegate.target as AnyObject)
    }
    
    init(selector: SelectorNode) {
        self.selector = selector
        self.id = ObjectIdentifier(selector.target as AnyObject)
    }

    init(block: BlockNode) {
        self.blockObj = block
        self.id = ObjectIdentifier(block.target as AnyObject)
    }
    
    static func == (lhs: WeakObserver, rhs: WeakObserver) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        // Hash on the object identity of the underlying delegate (or 0 if it has deallocated)
        hasher.combine(id)
    }
}

extension WeakObserver {
    func isNull() -> Bool {
        (delegate == nil || delegate?.target == nil) &&
        (blockObj == nil || blockObj?.target == nil) &&
        (selector == nil || selector?.target == nil)
    }
    
    func isSame(_ obj: AnyObject) -> Bool {
        ObjectIdentifier(obj) == id
    }
}

class DelegateNode {
    weak var target: CustomNotificationProtocol?
    
    init(target: CustomNotificationProtocol) {
        self.target = target
    }
}

class SelectorNode {
    weak var target: AnyObject?
    let selector: Selector
    
    init(target: AnyObject, selector: Selector) {
        self.target = target
        self.selector = selector
    }
}

class BlockNode {
    weak var target: AnyObject?
    private(set) var block: (([AnyHashable: Any]?) -> Void)?

    init(target: AnyObject, block: (([AnyHashable: Any]?) -> Void)?) {
        self.target = target
        self.block = block
    }
}
