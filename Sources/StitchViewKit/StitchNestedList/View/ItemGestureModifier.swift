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
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        self.dragY = gesture.location.y
                    }
                    .onEnded { _ in
                        self.dragY = nil
                    }
            )
    }
}
