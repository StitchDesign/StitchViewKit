//
//  File.swift
//
//
//  Created by Elliot Boschwitz on 1/26/24.
//

import Foundation
import SwiftUI

struct DragIndexReader<Data: StitchNestedListElement>: ViewModifier {
    let item: Data
    @Binding var sidebarItemDragged: Data?
    @Binding var dragCandidateItemId: Data.ID?
    let dragPosition: CGPoint?
    let yOffsetDragHack: CGFloat
    let isLastElement: Bool
    
    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: self.dragPosition, initial: true) {
                            guard var dragPosition = self.dragPosition else {
                                self.dragCandidateItemId = nil
                                self.sidebarItemDragged = nil
                                return
                            }
                            
                            // Manual offset to get drag to match boundary boxes better
                            dragPosition.y += yOffsetDragHack
                            
                            let frame = geometry.frame(in: .named(STITCHNESTEDLIST_COORDINATE_SPACE))
                            let didDragPastLastElement = isLastElement && dragPosition.y > frame.maxY && self.sidebarItemDragged != nil
                            let didDragToThisItem = dragPosition.y > frame.minY && dragPosition.y < frame.maxY
                            let newDrag = self.sidebarItemDragged == nil
                            
                            if didDragToThisItem {
                                self.dragCandidateItemId = item.id
                                
                                // Set the dragged item if previously nil, meaning drag state started here
                                if newDrag {
                                    self.sidebarItemDragged = item
                                }
                            }
                            else if didDragPastLastElement {
                                // Make drag ID nil if past last element
                                self.dragCandidateItemId = nil
                            }
                        }
                }
            }
    }
}
