//
//  File.swift
//  
//
//  Created by Elliot Boschwitz on 2/19/24.
//

import SwiftUI

public struct DeleteSelectionsButton<Element: StitchNestedListElement,
                              LabelView: View>: View {
    @Binding var data: [Element]
    @Binding var selections: Set<Element.ID>
    var deleteSelectionsCallback: ((Set<Element.ID>) -> ())?
    @ViewBuilder var label: () -> LabelView
    
    public init(data: Binding<[Element]>,
                selections: Binding<Set<Element.ID>>,
                deleteSelectionsCallback: ((Set<Element.ID>) -> ())? = nil,
                label: @escaping () -> LabelView) {
        self._data = data
        self._selections = selections
        self.deleteSelectionsCallback = deleteSelectionsCallback
        self.label = label
    }
    
    public var body: some View {
        Button {
            deleteSelectionsCallback?(selections)
            
            selections.forEach {
                data.remove($0)
            }
        } label: {
            label()
        }
    }
}
