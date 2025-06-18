import SwiftUI

struct StickerView: View {
    @Binding var sticker: Sticker
    @Binding var selectedStickerId: UUID?
    
    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero

    var isSelected: Bool {
        sticker.id == selectedStickerId && !sticker.isPlaced
    }

    var body: some View {
        if let uiImage = UIImage(data: sticker.imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .scaleEffect(currentScale * sticker.scale)
                .rotationEffect(currentRotation + .degrees(sticker.rotation))
                .position(sticker.position)
                .offset(dragOffset)
                .gesture(
                    sticker.isPlaced ? nil : DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            sticker.position = CGPoint(x: sticker.position.x + value.translation.width, y: sticker.position.y + value.translation.height)
                            dragOffset = .zero
                        }
                )
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            currentScale = value
                        }
                        .onEnded { value in
                            sticker.scale *= value
                            currentScale = 1.0
                        }
                )
                .simultaneousGesture(
                    RotationGesture()
                        .onChanged { value in
                            currentRotation = value
                        }
                        .onEnded { value in
                            sticker.rotation += value.degrees
                            currentRotation = .zero
                        }
                )
                .overlay(
                    isSelected ?
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 2)
                        : nil
                )
                .onTapGesture {
                    if !sticker.isPlaced {
                        selectedStickerId = sticker.id
                    }
                }
        }
    }
} 