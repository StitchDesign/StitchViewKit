//
//  File.swift
//  
//
//  Created by Elliot Boschwitz on 1/26/24.
//

import Foundation

public protocol StitchNestedListElement: Identifiable, Equatable {
    var children: [Self]? { get set }
}

extension Array where Element: StitchNestedListElement {
    var flattenedItems: [Element] {
        self.flatMap { item in
            var items = [item]
            items += item.children?.flattenedItems ?? []
            return items
        }
    }
    
    /// Places an element after the location of some ID.
    mutating func insert(_ data: Element, after elementWithId: Element.ID) {
        for (index, item) in self.enumerated() {
            var item = item
            
            // Insert here if matching case
            if item.id == elementWithId {
                // Check if we can do insertion or need to append
                if index < self.count {
                    self.insert(data, at: index)
                } else {
                    self.append(data)
                }
                
                // Exit recursion on success
                return
            }
            
            // Recursively check children
            item.children?.insert(data, after: elementWithId)
            self[index] = item
        }
    }
    
    /// Places an element after the location of some ID.
    mutating func remove(_ elementWithId: Element.ID) {
        for (index, item) in self.enumerated() {
            var item = item
            
            // Insert here if matching case
            if item.id == elementWithId {
                // Check if we can do insertion or need to append
                self.remove(at: index)
                
                // Exit recursion on success
                return
            }
            
            // Recursively check children
            item.children?.remove(elementWithId)
            self[index] = item
        }
    }
}
