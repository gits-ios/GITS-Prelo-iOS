//
//  BFDataStructures.swift
//  BFKit
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 - 2016 Fabrizio Brancati. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

// MARK: - Stack class -

/// Primitive Stack implementation
open class Stack: CustomStringConvertible {
    /// Describe the Stack
    open var description: String {
        return "\(stack)"
    }
    
    /// Private, the array behind Stack
    fileprivate var stack: Array<AnyObject> = Array<AnyObject>()
    
    /**
     Returns if the Stack is empty or not
    
     - returns: Returns true if the Stack is empty, otherwise false
     */
    open func empty() -> Bool {
        return stack.isEmpty
    }
    
    /**
     Adds an element on top of the Stack
    
     - parameter object: The element to add
     */
    open func push(_ object: AnyObject) {
        stack.append(object)
    }
    
    /**
     Removes an element on top of the Stack
    
     - returns: Returns the removed element
     */
    open func pop() -> AnyObject? {
        var popped: AnyObject? = nil
        if !self.empty() {
            popped = stack[stack.count - 1]
            stack.remove(at: stack.count - 1)
        }
        
        return popped
    }
}

// MARK: - List class -

/// Primitive List implementation. In order to work, the List must contain only objects that is subclass of NSObject
open class List: CustomStringConvertible {
    /// Describe the List
    open var description: String {
        return "\(list)"
    }
    
    /// Private, the array behind the List
    fileprivate var list: Array<AnyObject> = Array<AnyObject>()
    
    /**
     Search an element and returns the index
    
     - parameter object: The element to search
    
     - returns: Returns the index of the searched element
     */
    open func search(_ object: AnyObject) -> Int? {
        for i in 0 ..< list.count {
            if object is NSObject {
                if list[i] as! NSObject == object as! NSObject {
                    return i
                }
            } else {
                return nil
            }
        }
        
        return nil
    }
    
    /**
     Search for an index and returns the element
    
     - parameter index: The index
    
     - returns: Returns the element of the searched index
     */
    open func search(_ index: Int) -> AnyObject? {
        return list.safeObjectAtIndex(index)
    }
    
    /**
     Insert an element in the List
    
     - parameter object: The element to insert in the List
     */
    open func insert(_ object: AnyObject) {
        list.append(object)
    }
    
    /**
     Delete an element in the List
     
     - parameter object: The object to be deleted
     
     - returns: Retruns true if removed, otherwise false
     */
    open func delete(_ object: AnyObject) -> Bool {
        let search = self.search(object)
        
        if search != nil {
            list.remove(at: search!)
            return true
        } else {
            return false
        }
    }
    
    /**
     Delete an element at the given index
    
     - parameter index: The index to delete
     */
    open func delete(_ index: Int) {
        list.remove(at: index)
    }
}

// MARK: - Queue class -

/// Primitive Queue implementation
open class Queue: CustomStringConvertible {
    /// Describe the Queue
    open var description: String {
        return "\(queue)"
    }
    
    /// Private, the array behind the Queue
    fileprivate var queue: Array<AnyObject> = Array<AnyObject>()
    
    /**
     Adds an element to the Queue
    
     - parameter object: The element to add
     */
    open func enqueue(_ object: AnyObject) {
        queue.append(object)
    }
    
    /**
     Dequeue the first element
     
     - returns: Retruns true if removed, otherwise false
     */
    open func dequeue() -> Bool {
        if queue.count > 0 {
            queue.remove(at: 0)
            return true
        } else {
            return false
        }
    }
    
    /**
     Returns the element on the top of the Queue
    
     - returns: Returns the element on the top of the Queue
     */
    open func top() -> AnyObject? {
        return queue.first
    }
    
    /**
     Remove all the elements in the Queue
     */
    open func emptyQueue() {
        queue.removeAll(keepingCapacity: false)
    }
}
