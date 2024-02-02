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
    let item: Data
    let isEditing: Bool
    let isParentSelected: Bool
    @Binding var selections: Set<Data.ID>
    let dragY: CGFloat?
    let yOffsetDragHack: CGFloat
    @Binding var sidebarItemDragged: Data?
    @Binding var dragCandidateItemId: Data.ID?
    let lastElementId: Data.ID?
    @ViewBuilder var itemViewBuilder: (Data, Bool) -> RowContent
    
    var isDragging: Bool {
        self.sidebarItemDragged?.id == item.id
    }

    var isSelected: Bool {
        self.selections.contains(item.id)
    }
    
    var isLastElement: Bool {
        item.id == lastElementId
    }

    var body: some View {
        Group {
            itemViewBuilder(item, isSelected)
            .modifier(DragIndexReader(item: item,
                                      sidebarItemDragged: $sidebarItemDragged,
                                      dragCandidateItemId: $dragCandidateItemId,
                                      dragY: dragY,
                                      yOffsetDragHack: yOffsetDragHack,
                                      isLastElement: isLastElement))

            if let children = item.children {
                ForEach(children) { itemChild in
                    StitchNestedListItemView(item: itemChild,
                    isEditing: isEditing,
                                    isParentSelected: self.isSelected,
                                    selections: $selections,
                                    dragY: dragY,
                                    yOffsetDragHack: yOffsetDragHack,
                                    sidebarItemDragged: $sidebarItemDragged,
                                    dragCandidateItemId: $dragCandidateItemId,
                                             lastElementId: lastElementId,
                                             itemViewBuilder: itemViewBuilder)
                }
                .padding(.leading, 40)
            }
        }
        // Hide items if dragging
        .opacity(isDragging ? 0 : 1)
        .onChange(of: isParentSelected, initial: true) {
            if isParentSelected {
                selections.insert(item.id)
            } else {
                selections.remove(item.id)
            }
        }
    }
}

