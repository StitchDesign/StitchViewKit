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
    static func createId() -> Self.ID
}

extension StitchNestedListElement {
    var isGroup: Bool {
        self.children != nil
    }
    
    /// Recursively grabs all elements from self and children.
    public var allElementIds: Set<Self.ID> {
        let ids = Set([self.id])
        guard let children = self.children else {
            return ids
        }
        
        let childrenIds = Set(children.flatMap { $0.allElementIds })
        return ids.union(childrenIds)
    }
}

enum GroupCandidate<Element: StitchNestedListElement> {
    // Nil for root case
    case valid(Element.ID?)
    case invalid
}

extension GroupCandidate {
    var isValidGroup: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var parentId: Element.ID? {
        switch self {
        case .valid(let id):
            return id
        case .invalid:
            return nil
        }
    }
}

extension Array where Element: StitchNestedListElement {
    /// Returns `true` if selections meet the following criteria:
    /// 1. All top-level selections are located in same hierarchy (contain the same parent)
    /// 2. All top-level selections in turn have all of their children selected
    func containsValidGroup(from selections: Set<Element.ID>,
                            // Tracks the parent hierarchy of this candidate group, nil = root
                            parentLayerGroupId: Element.ID? = nil) -> GroupCandidate<Element> {
        // Invalid if data or selections are empty
        guard !self.isEmpty && !selections.isEmpty else {
            return .invalid
        }
        
        // Keeps track of of what a valid selection set would look like given top-level selections,
        // meaning if some children aren't selected it won't match this.
        let validSelectedSet = self.reduce(into: Set<Element.ID>()) { result, element in
            guard selections.contains(element.id) else {
                return
            }
            
            result = result.union(element.allElementIds)
        }
        
        // Recursively check children if no selections found at this hierarachy
        guard !validSelectedSet.isEmpty else {
            let recursiveChecks = self.compactMap {
                $0.children?.containsValidGroup(from: selections,
                                                parentLayerGroupId: $0.id)
            }
            for result in recursiveChecks {
                switch result {
                case .invalid:
                    continue
                case .valid(let parentId):
                    return .valid(parentId)
                }
            }
            
            return .invalid
        }
        
        // Non-empty selections mean we've identified the highest hierarchy of selections, and
        // therefore must match our valid selection set
        guard validSelectedSet == selections else {
            return .invalid
        }
            
        // All elements are at same hierarchy so we can grab any element to get parent
        let parentGroupId = self.first { selections.contains($0.id) }?.id
        return .valid(parentGroupId)
    }
    
    var flattenedItems: [Element] {
        self.flatMap { item in
            var items = [item]
            items += item.children?.flattenedItems ?? []
            return items
        }
    }
    
    /// Places an element after the location of some ID.
    /// If `elementWithId` is nil we insert in begginging
    mutating func insert(_ data: Element,
                         after elementWithId: Element.ID?) {
        let _ = self.insert(data, after: elementWithId, isRootLevel: true)
    }
    
    private mutating func insert(_ data: Element,
                         after elementWithId: Element.ID?,
                                 isRootLevel: Bool) -> Bool {
        guard let elementWithId = elementWithId else {
            self.insert(data, at: 0)
            return true
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
                return true
            }
            
            // Recursively check children, if result is true then we've found the element
            if item.children?.insert(data,
                                     after: elementWithId,
                                     isRootLevel: false) ?? false {
                self[index] = item
                return true
            }
        }
        
        // Insert at end if no match
        if isRootLevel {
            self.append(data)
            return true
        } else {
            // No match found at nested level
            return false
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
    
    /// Returns the lowest index amonst a list of selections. Nil result means none found.
    private func findLowestIndex(amongst ids: Set<Element.ID>) -> Int? {
        self.enumerated()
            .filter { ids.contains($0.element.id) }
            .min { $0.offset < $1.offset }?.offset
    }
    
    public mutating func createGroup(newGroupId: Element.ID,
                                     parentLayerGroupId: Element.ID?,
                                     selections: Set<Element.ID>) {
        let idsAtHierarchy: [Element.ID?] = self.map { $0.id }
        let atCorrectHierarchy = parentLayerGroupId == nil || idsAtHierarchy.contains(parentLayerGroupId)
        
        // Recursively search children until we find the parent layer ID
        guard atCorrectHierarchy,
        // Find the selected element at the minimum index to determine location of new group node
              let newGroupIndex = self.findLowestIndex(amongst: selections) else {
            self = self.map { element in
                var element = element
                element.children?.createGroup(newGroupId: newGroupId,
                                                    parentLayerGroupId: parentLayerGroupId,
                                                    selections: selections)
                return element
            }
            return
        }
        
        var newGroupData = Element(id: newGroupId, children: [])
        
        // Update selected nodes to report to new group node
        self.enumerated()
            .reversed() // avoids index out of bounds for multiple selections!
            .forEach { index, element in
            // Get layer data from sidebar to add to group
            guard selections.contains(element.id) else {
                // Skip if not one of our selections
                return
            }
            // Remove this element from list
            self.remove(at: index)
            
            // Re-add it to group
            newGroupData.children?.append(element)
        }

        // Re-reverse children since because of our previous reversed loop
        newGroupData.children = newGroupData.children?.reversed()
        
        // Add new group node to sidebar
        self.insert(newGroupData, at: newGroupIndex)
    }
}
