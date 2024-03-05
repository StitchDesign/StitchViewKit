//
//  File.swift
//
//
//  Created by Elliot Boschwitz on 1/26/24.
//

import Foundation
import SwiftUI

struct ItemGestureModifier: ViewModifier {
    @Binding var dragPosition: CGPoint?
    let isSlideMenuOpen: Bool
    let isEditing: Bool
    
    @GestureState private var dragState = DragState.inactive
    
    enum DragState {
        case inactive
        case pressing
        case dragging(position: CGPoint)
        
        var position: CGPoint? {
            switch self {
            case .inactive, .pressing:
                return nil
            case .dragging(let position):
                return position
            }
        }
        
        var isActive: Bool {
            switch self {
            case .inactive:
                return false
            case .pressing, .dragging:
                return true
            }
        }
        
        var isDragging: Bool {
            switch self {
            case .inactive, .pressing:
                return false
            case .dragging:
                return true
            }
        }
    }
    
    var longPress: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .sequenced(before: DragGesture(coordinateSpace: .named(STITCHNESTEDLIST_COORDINATE_SPACE)))
            .updating($dragState) { value, state, transaction in
                switch value {
                    // Long press begins.
                case .first(true):
                    state = .pressing
                    
                    // Long press confirmed, dragging may begin.
                case .second(true, let drag):
                    if let newDrag = drag?.location {
                        state = .dragging(position: newDrag)
                    }
                    
                    // Dragging ended or the long press cancelled.
                default:
                    state = .inactive
                    self.dragPosition = nil
                }
            }
            .onEnded { finished in
                self.dragPosition = nil
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .named(STITCHNESTEDLIST_COORDINATE_SPACE))
            .onChanged { gesture in
                self.dragPosition = gesture.location
            }
            .onEnded { _ in
                self.dragPosition = nil
            }
    }
    
    var enableLongPress: Bool {
        !isEditing && !isSlideMenuOpen
    }
    
    func body(content: Content) -> some View {
        content
#if !targetEnvironment(macCatalyst)
            .gesture(longPress)
#else
        // high pri needed for enable long press here
            .gesture(
                isEditing ? dragGesture : nil
            )
            .gesture(
                // Long press is only for when we're not editing
                enableLongPress ? longPress : nil
            )
#endif
            .onChange(of: self.dragState.position) {
                self.dragPosition = self.dragState.position
            }
    }
}
