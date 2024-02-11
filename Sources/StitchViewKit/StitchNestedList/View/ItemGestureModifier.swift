//
//  File.swift
//
//
//  Created by Elliot Boschwitz on 1/26/24.
//

import Foundation
import SwiftUI

struct ItemGestureModifier: ViewModifier {
    @Binding var dragY: CGFloat?
    
#if !targetEnvironment(macCatalyst)
    @GestureState private var dragState = DragState.inactive
    
    enum DragState {
        case inactive
        case pressing
        case dragging(yPosition: CGFloat)
        
        var yPosition: CGFloat? {
            switch self {
            case .inactive, .pressing:
                return nil
            case .dragging(let yPosition):
                return yPosition
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
                    if let newDragY = drag?.location.y {
                        state = .dragging(yPosition: newDragY)
                    }
                    
                    // Dragging ended or the long press cancelled.
                default:
                    state = .inactive
                    self.dragY = nil
                }
            }
            .onEnded { finished in
                self.dragY = nil
            }
    }
    #else
    var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .named(STITCHNESTEDLIST_COORDINATE_SPACE))
            .onChanged { gesture in
                self.dragY = gesture.location.y
            }
            .onEnded { _ in
                self.dragY = nil
            }
    }
#endif
    
    func body(content: Content) -> some View {
        content
#if !targetEnvironment(macCatalyst)
            .gesture(
                longPress
            )
            .onChange(of: self.dragState.yPosition) {
                self.dragY = self.dragState.yPosition
            }
#else
            .simultaneousGesture(
                dragGesture
            )
#endif
    }
}
