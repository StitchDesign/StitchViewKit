//
//  File.swift
//  
//
//  Created by Elliot Boschwitz on 1/26/24.
//

import Foundation

public protocol StitchNestedListElement: Identifiable, Equatable {
    var children: [Self]? { get set }
    init(id: Self.ID, children: [Self]?)
}

extension StitchNestedListElement {
    var isGroup: Bool {
        self.children != nil
    }
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
    /// If `elementWithId` is nil we insert in begginging
    mutating func insert(_ data: Element, after elementWithId: Element.ID?) {
        guard let elementWithId = elementWithId else {
            self.insert(data, at: 0)
            return
        }

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
    
    public func get(_ id: Element.ID) -> Element? {
        for item in self {
            if item.id == item.id {
                return item
            }
            
            // Recursively check children
            return item.children?.get(id)
        }
        
        return nil
    }
    
    /// The "highest" element ID actually returns the element before the highest. Used for creating groups when selections get deleted.
    /// If nil, we translate this as meaning we return to beginning of list.
    func findHighestElementId(amongst ids: Set<Element.ID>) -> Element.ID? {
        var minElementId: Element.ID?
        var minIndex = ids.count    // arbitrary max number at start
        
        // Flatten nested list to determine index
        let flattenedItems = self.flattenedItems
        
        ids.forEach { id in
            if let index = flattenedItems.firstIndex(where: { $0.id == id }) {
                if index < minIndex {
                    minIndex = index
                    
                    minElementId = flattenedItems[safe: index - 1]?.id
                }
            }
        }
        
        return minElementId
    }
    
    public mutating func createGroup(newGroupId: Element.ID,
                                     selections: Set<Element.ID>) {
        var newGroupData = Element(id: newGroupId, children: [])
        
        // Find the selected element at the minimum index to determine location of new group node
        let highestSelectedElement = self.findHighestElementId(amongst: selections)

        // Update selected nodes to report to new group node
        selections.forEach { id in
            // Get layer data from sidebar to add to group
            if let childData = self.get(id) {
                // Remove this element from list
                self.remove(id)

                // Re-add it to group
                newGroupData.children?.append(childData)
            }
        }

        // Add new group node to sidebar
        self.insert(newGroupData, after: highestSelectedElement)
    }
}
