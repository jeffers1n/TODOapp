import SwiftUI

struct HomeView: View {
    @EnvironmentObject var stickerVM: StickerViewModel
    @State private var selectedStickerId: UUID?
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Image("backgroundImage")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()

                    VStack {
                        Spacer()
                        Image("characterImage")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 700)
                            .offset(x: 210, y:10)
                        Spacer()
                    }
                    
                    ForEach($stickerVM.stickers) { $sticker in
                        StickerView(sticker: $sticker, selectedStickerId: $selectedStickerId)
                    }
                }
                .navigationTitle("Мой прогресс")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if let placingId = stickerVM.placingStickerID {
                            Button("Приклеить") {
                                stickerVM.placeSticker(id: placingId)
                            }
                        }
                    }
                }
                .onAppear {
                    if let placingId = stickerVM.placingStickerID {
                        selectedStickerId = placingId
                    }
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
} 
