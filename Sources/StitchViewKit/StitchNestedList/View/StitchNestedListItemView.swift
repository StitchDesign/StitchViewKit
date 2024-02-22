//
//  File.swift
//
//
//  Created by Elliot Boschwitz on 1/26/24.
//

import Foundation
import SwiftUI
import SwipeActions

struct StitchNestedListItemView<Data: StitchNestedListElement,
                                RowContent: View,
                                TrailingActions: View>: View {
    let item: Data
    let isEditing: Bool
    let isParentSelected: Bool
    @Binding var selections: Set<Data.ID>
    let dragPosition: CGPoint?
    @Binding var sidebarItemDragged: Data?
    @Binding var dragCandidateItemId: Data.ID?
    @Binding var isSlideMenuOpen: Bool
    let lastElementId: Data.ID?
    var onSelection: ((Data) -> Void)?
    @ViewBuilder var itemViewBuilder: (Data, Bool) -> RowContent
    @ViewBuilder var trailingActions: (Data) -> TrailingActions
    
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
            gestureView
            
            if let children = item.children {
                ForEach(children) { itemChild in
                    StitchNestedListItemView(item: itemChild,
                                             isEditing: isEditing,
                                             isParentSelected: self.isSelected,
                                             selections: $selections,
                                             dragPosition: dragPosition,
                                             sidebarItemDragged: $sidebarItemDragged,
                                             dragCandidateItemId: $dragCandidateItemId,
                                             isSlideMenuOpen: $isSlideMenuOpen,
                                             lastElementId: lastElementId,
                                             onSelection: onSelection,
                                             itemViewBuilder: itemViewBuilder,
                                             trailingActions: trailingActions)
                }
                .padding(.leading, GROUP_INDENDATION)
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
    
    @ViewBuilder
    var gestureView: some View {
        if isEditing {
            // No swipe actions but enable selections
            itemView
                .onTapGesture {
                    if selections.contains(item.id) {
                        selections.remove(item.id)
                    } else {
                        selections.insert(item.id)
                    }
                }
        } else {
            SwipeView {
                itemView
                    .onTapGesture {
                        onSelection?(item)
                    }
            } trailingActions: { context in
                trailingActions(item)
                    .onChange(of: context.state.wrappedValue, initial: true) {
                        self.isSlideMenuOpen = context.state.wrappedValue == .expanded
                    }
            }
            .swipeActionCornerRadius(8)
            .swipeActionsMaskCornerRadius(8)
        }
    }
    
    @ViewBuilder
    var itemView: some View {
        HStack {
            itemViewBuilder(item, isSelected)
            Spacer()
        }
        .contentShape(Rectangle()) // fixes gesture targets
            .modifier(DragIndexReader(item: item,
                                      sidebarItemDragged: $sidebarItemDragged,
                                      dragCandidateItemId: $dragCandidateItemId,
                                      dragPosition: dragPosition,
                                      isLastElement: isLastElement))
    }
}

