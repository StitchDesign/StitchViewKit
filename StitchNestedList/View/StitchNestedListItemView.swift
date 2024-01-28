//
//  File.swift
//  
//
//  Created by Elliot Boschwitz on 1/26/24.
//

import Foundation
import SwiftUI


struct StitchNestedListItemView<Data: StitchNestedListElement,
                                RowContent: View>: View {
    @State private var isSelected = false
    
    let item: Data
    let isParentSelected: Bool
    @Binding var selections: Set<Data.ID>
    let dragY: CGFloat?
    let yOffsetDragHack: CGFloat
    @Binding var sidebarItemDragged: Data?
    @Binding var dragCandidateItemId: Data.ID?
    @ViewBuilder var itemViewBuilder: (Data) -> RowContent
    
    var isDragging: Bool {
        self.sidebarItemDragged?.id == item.id
    }
    
    var body: some View {
        Group {
            itemViewBuilder(item)
            .modifier(DragIndexReader(item: item,
                                      sidebarItemDragged: $sidebarItemDragged,
                                      dragCandidateItemId: $dragCandidateItemId,
                                      dragY: dragY,
                                      yOffsetDragHack: yOffsetDragHack))

            if let children = item.children {
                ForEach(children) { itemChild in
                    StitchNestedListItemView(item: itemChild,
                                    isParentSelected: self.isSelected,
                                    selections: $selections,
                                    dragY: dragY,
                                    yOffsetDragHack: yOffsetDragHack,
                                    sidebarItemDragged: $sidebarItemDragged,
                                    dragCandidateItemId: $dragCandidateItemId,
                                             itemViewBuilder: itemViewBuilder)
                }
                .padding(.leading, 40)
            }
        }
        // Hide items if dragging
        .opacity(isDragging ? 0 : 1)
        .onChange(of: selections, initial: true) {
            isSelected = selections.contains(item.id)
        }
        .onChange(of: isParentSelected, initial: true) {
            if isParentSelected {
                selections.insert(item.id)
            } else {
                selections.remove(item.id)
            }
        }
    }
}

