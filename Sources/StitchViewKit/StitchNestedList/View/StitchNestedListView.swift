//
//  StitchNestList.swift
//
//
//  Created by Elliot Boschwitz on 1/26/24.
//

import Foundation
import SwiftUI

let STITCHNESTEDLIST_COORDINATE_SPACE = "STITCH_NESTEDLIST_COORDINATE_SPACE"
let SWIPE_FULL_CORNER_RADIUS = 8

public struct StitchNestedList<Data: StitchNestedListElement, RowContent: View>: View {
    @Environment(\.editMode) var editMode
    
    @State private var dragY: CGFloat? = .zero
    @State private var sidebarItemDragged: Data? = nil
    @State private var dragCandidateItemId: Data.ID? = nil
    
    @Binding var data: [Data]
    @Binding var selections: Set<Data.ID>
    /// Item locations fail to use named coordinate space, hack offers a temporary workaround
    let yOffsetDragHack: CGFloat
    @ViewBuilder var itemViewBuilder: (Data, Bool) -> RowContent
    
    public init(data: Binding<[Data]>,
                selections: Binding<Set<Data.ID>>,
                yOffsetDragHack: CGFloat,
                itemViewBuilder: @escaping (Data, Bool) -> RowContent) {
        self._data = data
        self._selections = selections
        self.yOffsetDragHack = yOffsetDragHack
        self.itemViewBuilder = itemViewBuilder
    }
    
    /// We pass in an empty object when editing is disabled to prevent the sidebar from  updating the navigation stack
    var activeSelections: Binding<Set<Data.ID>> {
        self.isEditing ? self.$selections : .constant(.init())
    }
    
    var isEditing: Bool {
        self.editMode?.wrappedValue.isEditing ?? false
    }
    
    var lastElementId: Data.ID? {
        self.data.flattenedItems.last?.id
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            List($data,
                 editActions: .delete) { item in
                StitchNestedListItemView(item: item.wrappedValue,
                                         isEditing: isEditing,
                                         isParentSelected: false,
                                         selections: $selections,
                                         dragY: dragY,
                                         yOffsetDragHack: self.yOffsetDragHack,
                                         sidebarItemDragged: self.$sidebarItemDragged,
                                         dragCandidateItemId: self.$dragCandidateItemId,
                                         lastElementId: lastElementId,
                                         itemViewBuilder: itemViewBuilder)
            }
            // MARK: disable for now, see if necessary
//            .scrollDisabled(dragY != nil)
            .modifier(ItemGestureModifier(dragY: $dragY))
            if let draggedItem = self.sidebarItemDragged,
               let dragY = dragY {
                VStack(spacing: .zero) {
                    StitchNestedListItemView(item: draggedItem,
                                             isEditing: false,
                                             isParentSelected: false,
                                             selections: .constant(.init()),
                                             dragY: nil,
                                             yOffsetDragHack: .zero,
                                             sidebarItemDragged: .constant(nil),
                                             dragCandidateItemId: .constant(nil),
                                             lastElementId: nil,
                                             itemViewBuilder: itemViewBuilder)
                    .transition(.opacity)
                    .padding(.horizontal)
                }
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .offset(y: dragY)
                .disabled(true)
            }
        }
        .coordinateSpace(name: STITCHNESTEDLIST_COORDINATE_SPACE)
        .animation(.easeInOut, value: self.data)
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
    }
}
