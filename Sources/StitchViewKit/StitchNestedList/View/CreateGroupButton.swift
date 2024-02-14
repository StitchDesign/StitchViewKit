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
    @Binding var editMode: EditMode
    let groupCreatedCallback: (Element) -> ()
    @ViewBuilder var label: () -> LabelView
    
    public init(data: Binding<[Element]>,
                selections: Binding<Set<Element.ID>>,
                editMode: Binding<EditMode>,
                groupCreatedCallback: @escaping (Element) -> (),
                label: @escaping () -> LabelView) {
        self._data = data
        self._selections = selections
        self._editMode = editMode
        self.groupCreatedCallback = groupCreatedCallback
        self.label = label
    }
    
    var groupResult: GroupCandidate<Element> {
        self.data.containsValidGroup(from: selections)
    }
    
    public var body: some View {
        Button {
            let newId = Element.createId()
            self.data.createGroup(newGroupId: newId,
                                  parentLayerGroupId: groupResult.parentId,
                                  selections: selections)
            
            self.selections = .init()
            self.editMode = .inactive

            guard let newGroupLayer = self.data.get(newId) else {
                #if DEBUG
                fatalError()
                #endif
                return
            }
            
            self.groupCreatedCallback(newGroupLayer)
        } label: {
            label()
        }
        .disabled(!groupResult.isValidGroup)
    }
}

