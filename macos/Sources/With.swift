import Foundation


protocol With { }

extension With where Self: AnyObject {
    @inlinable @discardableResult
    func setting<V>(_ keyPath: ReferenceWritableKeyPath<Self, V>, to value: V) -> Self {
        self[keyPath: keyPath] = value
        return self
    }

    @inlinable
    func `do`(_ block: (Self) throws -> Void) rethrows {
        try block(self)
    }

    @inlinable @discardableResult
    func `then`(_ block: (Self) throws -> Void) rethrows -> Self {
        try block(self)
        return self
    }
}

extension NSObject: With { }
