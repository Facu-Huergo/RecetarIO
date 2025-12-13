import SwiftUI
import UniformTypeIdentifiers

struct ImportRecipeButton: View {
    @ObservedObject var viewModel: RecipeViewModel
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Button(action: {
            showingFilePicker = true
        }) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("Importar")
            }
            .font(.subheadline)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json], // CAMBIO AQUÍ: Buscar archivos JSON específicamente
            allowsMultipleSelection: false
        ){ result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    if viewModel.importRecipe(from: url) {
                        alertMessage = "¡Receta importada exitosamente!"
                    } else {
                        alertMessage = "Error: No se pudo leer la receta. Asegúrate de usar un archivo exportado de RecetarIO."
                    }
                    showingAlert = true
                }
            case .failure(let error):
                alertMessage = "Error: \(error.localizedDescription)"
                showingAlert = true
            }
        }
        .alert("Importar Receta", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}
