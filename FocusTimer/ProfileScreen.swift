import SwiftUI
import PhotosUI

struct ProfileScreen: View {
    @State private var name = PrefsManager.shared.userName
    @State private var photoImage: Image?
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 24) {
            Text("Профиль")
                .font(.title.bold())

            PhotosPicker(selection: $pickerItem, matching: .images) {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 120, height: 120)

                    if let photoImage {
                        photoImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onChange(of: pickerItem) { newItem in
                Task {
                    guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                    if let url = PrefsManager.shared.savePhoto(data: data),
                       let uiImage = UIImage(contentsOfFile: url.path) {
                        photoImage = Image(uiImage: uiImage)
                    }
                }
            }

            TextField("Имя", text: $name)
                .textFieldStyle(.roundedBorder)
                .onChange(of: name) { PrefsManager.shared.userName = $0 }

            Spacer()
        }
        .padding(24)
        .onAppear {
            if let url = PrefsManager.shared.photoURL,
               let uiImage = UIImage(contentsOfFile: url.path) {
                photoImage = Image(uiImage: uiImage)
            }
        }
    }
}
