//
//  UngroupButton.swift
//
//
//  Created by Elliot Boschwitz on 2/19/24.
//

import Foundation
import SwiftUI

public struct UngroupButton<Element: StitchNestedListElement,
                            LabelView: View>: View {
    @Binding var data: [Element]
    @Binding var selections: Set<Element.ID>
    @Binding var editMode: EditMode
    let ungroupCallback: ((Element.ID) -> ())?
    @ViewBuilder var label: () -> LabelView
    
    public init(data: Binding<[Element]>,
                selections: Binding<Set<Element.ID>>,
                editMode: Binding<EditMode>,
                ungroupCallback: ((Element.ID) -> ())? = nil,
                label: @escaping () -> LabelView) {
        self._data = data
        self._selections = selections
        self._editMode = editMode
        self.ungroupCallback = ungroupCallback
        self.label = label
    }
    
    var selectedGroupId: Element.ID? {
        // Helper only returns successful result if all selections are in a group
        data.containsValidUngroup(from: selections).parentId
    }
    
    // Selections contian one item which is a group
    var containsValidUngroup: Bool {
        self.selectedGroupId != nil
    }
    
    public var body: some View {
        Button {
            if let selectedGroupId = self.selectedGroupId {
                // Update data list
                self.data = self.data.ungroup(selectedGroupId: selectedGroupId)
                
                // Run the passed-in callback
                self.ungroupCallback?(selectedGroupId)
            }
            
            self.selections = .init()
            self.editMode = .inactive
        } label: {
            label()
        }
        .disabled(!containsValidUngroup)
    }
}

