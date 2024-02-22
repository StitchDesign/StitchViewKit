//
//  CreateGroupButton.swift
//
//
//  Created by Elliot Boschwitz on 2/13/24.
//

import Foundation
import SwiftUI

public struct CreateGroupButton<Element: StitchNestedListElement,
                            LabelView: View>: View {
    @Binding var data: [Element]
    @Binding var selections: Set<Element.ID>
    @Binding var isEditing: Bool
    let groupCreatedCallback: ((Element) -> ())?
    @ViewBuilder var label: () -> LabelView
    
    public init(data: Binding<[Element]>,
                selections: Binding<Set<Element.ID>>,
                isEditing: Binding<Bool>,
                groupCreatedCallback: ((Element) -> ())? = nil,
                label: @escaping () -> LabelView) {
        self._data = data
        self._selections = selections
        self._isEditing = isEditing
        self.groupCreatedCallback = groupCreatedCallback
        self.label = label
    }
    
    var groupResult: GroupCandidate<Element> {
        self.data.containsValidGroup(from: selections)
    }
    
    public var body: some View {
        Button {
            let newId = Element.createId()

            if let newGroup = self.data.createGroup(newGroupId: newId,
                                  parentLayerGroupId: groupResult.parentId,
                                  selections: selections) {
                // Run the passed-in callback
                self.groupCreatedCallback?(newGroup)
                
                // Insert new group in list
                self.data.insertGroup(group: newGroup,
                                      selections: selections)
            }
            
            self.selections = .init()
            self.isEditing = false
        } label: {
            label()
        }
        .disabled(!groupResult.isValidGroup)
    }
}

