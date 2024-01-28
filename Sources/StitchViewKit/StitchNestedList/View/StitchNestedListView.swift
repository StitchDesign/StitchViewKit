//
//  StitchNestList.swift
//
//
//  Created by Elliot Boschwitz on 1/26/24.
//

import Foundation
import SwiftUI

let STITCHNESTEDLIST_COORDINATE_SPACE = "STITCH_NESTEDLIST_COORDINATE_SPACE"

public struct StitchNestedList<Data: StitchNestedListElement, RowContent: View>: View {
    @State private var selections = Set<Data.ID>()
    @State private var dragY: CGFloat? = .zero
    @State private var sidebarItemDragged: Data? = nil
    @State private var dragCandidateItemId: Data.ID? = nil
    
    @Binding var data: [Data]
    /// Item locations fail to use named coordinate space, hack offers a temporary workaround
    let yOffsetDragHack: CGFloat
    @ViewBuilder var itemViewBuilder: (Data) -> RowContent
    
    public init(data: Binding<[Data]>,
                yOffsetDragHack: CGFloat,
     itemViewBuilder: @escaping (Data) -> RowContent) {
        self._data = data
        self.yOffsetDragHack = yOffsetDragHack
        self.itemViewBuilder = itemViewBuilder
    }
    
    public var body: some View {
        ZStack {
            List {
                ForEach(data) { item in
                    StitchNestedListItemView(item: item,
                                             isParentSelected: false,
                                             selections: $selections,
                                             dragY: dragY,
                                             yOffsetDragHack: self.yOffsetDragHack,
                                             sidebarItemDragged: self.$sidebarItemDragged,
                                             dragCandidateItemId: self.$dragCandidateItemId,
                                             itemViewBuilder: itemViewBuilder)
                }
            }
            .disabled(sidebarItemDragged != nil)
            .overlay {
                if let draggedItem = self.sidebarItemDragged,
                   let dragY = dragY {
                    VStack {
                        StitchNestedListItemView(item: draggedItem,
                                                  isParentSelected: false,
                                                  selections: .constant(.init()),
                                                  dragY: nil,
                                                  yOffsetDragHack: .zero,
                                                  sidebarItemDragged: .constant(nil),
                                                  dragCandidateItemId: .constant(nil),
                                                 itemViewBuilder: itemViewBuilder)
                        .transition(.opacity)
                        
                        // Overlay is off by about 30 pixels
                        .padding(.leading, 30)
                        .offset(y: dragY)
                        .disabled(true)
                        
                        Spacer()
                    }
                }
            }
            .modifier(ItemGestureModifier(dragY: $dragY))
        }
        .coordinateSpace(name: STITCHNESTEDLIST_COORDINATE_SPACE)
        .animation(.easeInOut, value: self.data)
        .onChange(of: self.dragCandidateItemId) {
            guard let sidebarItemDragged = self.sidebarItemDragged,
                  // do nothing if candidate location is same as current item
                  sidebarItemDragged.id != self.dragCandidateItemId else {
                return
            }
            
            // Add item back to list at last tracked index
            if let item = self.sidebarItemDragged,
               let dragCandidateItemId = self.dragCandidateItemId {
                // Remove item from old location
                self.data.remove(sidebarItemDragged.id)
                
                // Determines index at hierarchical data
                self.data.insert(item, after: dragCandidateItemId)
            } else {
                print("StitchNestedViewList error: unable to find location on drag.")
            }
        }
    }
}
