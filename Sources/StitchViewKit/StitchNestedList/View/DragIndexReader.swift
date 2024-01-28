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
    let dragY: CGFloat?
    let yOffsetDragHack: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: self.dragY, initial: true) {
                            guard var dragY = self.dragY else {
                                self.dragCandidateItemId = nil
                                self.sidebarItemDragged = nil
                                return
                            }
                            
                            // Manual offset to get drag to match boundary boxes better
                            dragY += yOffsetDragHack
                            
                            let frame = geometry.frame(in: .named(STITCHNESTEDLIST_COORDINATE_SPACE))
                            
                            let didDragToThisItem = dragY > frame.minY && dragY < frame.maxY
                            let newDrag = self.sidebarItemDragged == nil
                            
                            if didDragToThisItem {
                                self.dragCandidateItemId = item.id
                                
                                // Set the dragged item if previously nil, meaning drag state started here
                                if newDrag {
                                    self.sidebarItemDragged = item
                                }
                            }
                        }
                }
            }
    }
}
