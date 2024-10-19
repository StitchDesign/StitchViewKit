//
//  StitchNestList.swift
//
//
//  Created by Elliot Boschwitz on 1/26/24.
//

import Foundation
import SwiftUI
import SwipeActions

let STITCHNESTEDLIST_COORDINATE_SPACE = "STITCH_NESTEDLIST_COORDINATE_SPACE"
let SWIPE_FULL_CORNER_RADIUS = 8
let GROUP_INDENDATION: CGFloat = 40

public struct StitchNestedList<Data: StitchNestedListElement,
                               RowContent: View,
                               TrailingActions: View>: View {
    @State private var dragPosition: CGPoint? = .zero
    @State private var sidebarItemDragged: Data? = nil
    @State private var dragCandidateItemId: Data.ID? = nil
    @State private var isSlideMenuOpen = false
    
    @Binding var data: [Data]
    @Binding var selections: Set<Data.ID>
    @Binding var isEditing: Bool
    
    var onSelection: ((Data) -> Void)?
    @ViewBuilder var itemViewBuilder: (Data, Bool) -> RowContent
    @ViewBuilder var trailingActions: (Data) -> TrailingActions
    
    public init(data: Binding<[Data]>,
                selections: Binding<Set<Data.ID>>,
                isEditing: Binding<Bool>,
                onSelection: ((Data) -> Void)? = nil,
                itemViewBuilder: @escaping (Data, Bool) -> RowContent,
                trailingActions: @escaping (Data) -> TrailingActions) {
        self._data = data
        self._selections = selections
        self._isEditing = isEditing
        self.onSelection = onSelection
        self.itemViewBuilder = itemViewBuilder
        self.trailingActions = trailingActions
    }
    
    /// We pass in an empty object when editing is disabled to prevent the sidebar from  updating the navigation stack
    var activeSelections: Binding<Set<Data.ID>> {
        self.isEditing ? self.$selections : .constant(.init())
    }
    
    var lastElementId: Data.ID? {
        self.data.flattenedItems.last?.id
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Scroll view used due to issues getting coordinateSpace to work
            // with list
            ScrollView(.vertical) {
                ForEach($data) { item in
                    StitchNestedListItemView(item: item.wrappedValue,
                                             isEditing: isEditing,
                                             isParentSelected: false,
                                             selections: $selections,
                                             dragPosition: dragPosition,
                                             sidebarItemDragged: self.$sidebarItemDragged,
                                             dragCandidateItemId: self.$dragCandidateItemId,
                                             isSlideMenuOpen: $isSlideMenuOpen,
                                             lastElementId: lastElementId,
                                             onSelection: onSelection,
                                             itemViewBuilder: itemViewBuilder,
                                             trailingActions: trailingActions)
                }
            }
            // Coordinate space outside of list view necessary
            .coordinateSpace(name: STITCHNESTEDLIST_COORDINATE_SPACE)
            // iPad needs scroll disabled to enable dragging items
            // MARK: scrolling seems ok now
//            .scrollDisabled(isEditing)
            .modifier(ItemGestureModifier(dragPosition: $dragPosition,
                                          isSlideMenuOpen: isSlideMenuOpen,
                                          isEditing: isEditing))
            if let draggedItem = self.sidebarItemDragged,
               let dragPosition = dragPosition {
                VStack(spacing: .zero) {
                    StitchNestedListItemView(item: draggedItem,
                                             isEditing: false,
                                             isParentSelected: false,
                                             selections: .constant(.init()),
                                             dragPosition: nil,
                                             sidebarItemDragged: .constant(nil),
                                             dragCandidateItemId: .constant(nil),
                                             isSlideMenuOpen: $isSlideMenuOpen,
                                             lastElementId: nil,
                                             onSelection: nil,
                                             itemViewBuilder: itemViewBuilder,
                                             trailingActions: trailingActions)
                    .transition(.opacity)
                }
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .offset(y: dragPosition.y)
                .disabled(true)
            }
        }
//        .animation(.easeInOut, value: self.data)
        .onChange(of: self.isEditing) {
            self.selections = .init()
        }
        .onChange(of: self.dragCandidateItemId) {
            guard let sidebarItemDragged = self.sidebarItemDragged,
                  // do nothing if candidate location is same as current item
                  sidebarItemDragged.id != self.dragCandidateItemId else {
                return
            }
            
            // Add item back to list at last tracked index
            if let item = self.sidebarItemDragged {
                // Remove item from old location
                self.data.remove(sidebarItemDragged.id)
                
                // Determines index at hierarchical data
                if let dragCandidateItemId = self.dragCandidateItemId {
                    self.data.insert(item, after: dragCandidateItemId)
                } else {
                    // If dragged candidate is nil then we dragged past last item
                    self.data.append(item)
                }
            } else {
                print("StitchNestedViewList error: unable to find location on drag.")
            }
        }
        .onChange(of: self.sidebarItemDragged?.id) {
            // Reset selection state when sidebar drag starts
            self.selections = .init()
        }
    }
}
