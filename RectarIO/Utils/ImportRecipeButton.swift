import SwiftUI
import UniformTypeIdentifiers

// MARK: - Tipo de archivo personalizado .rio
extension UTType {
    static var recetarioFile: UTType {
        UTType(exportedAs: "com.recetario.rio")
    }
}

struct ImportRecipeButton: View {
    @ObservedObject var viewModel: RecipeViewModel
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
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
            allowedContentTypes: [
                .recetarioFile,  // Nuestro tipo personalizado
                .json            // Mantener compatibilidad con JSON plano
            ],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Detectar el tipo de archivo
            let fileExtension = url.pathExtension.lowercased()
            
            switch fileExtension {
            case "rio":
                importRIOFile(url: url)
                
            case "json":
                importJSONFile(url: url)
                
            default:
                showError(
                    title: "Formato no soportado",
                    message: "Solo se aceptan archivos .rio o .json de RecetarIO"
                )
            }
            
        case .failure(let error):
            showError(
                title: "Error de importación",
                message: error.localizedDescription
            )
        }
    }
    
    // MARK: - Importar archivo .rio encriptado
    private func importRIOFile(url: URL) {
        if viewModel.importRecipe(from: url) {
            showSuccess(
                title: "¡Importación exitosa! 🎉",
                message: "La receta se agregó correctamente a tu colección."
            )
        } else {
            showError(
                title: "Error al importar",
                message: "El archivo .rio está corrupto o es inválido. Asegúrate de que sea un archivo exportado desde RecetarIO."
            )
        }
    }
    
    // MARK: - Importar JSON plano (legacy)
    private func importJSONFile(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            var recipe = try JSONDecoder().decode(Recipe.self, from: data)
            
            // Asignar nuevo ID
            recipe.id = UUID()
            recipe.dateCreated = Date()
            
            viewModel.recipes.append(recipe)
            viewModel.saveRecipes()
            
            showSuccess(
                title: "Importación exitosa",
                message: "Receta importada desde JSON. Te recomendamos usar archivos .rio para mayor seguridad."
            )
            
        } catch {
            showError(
                title: "Error al leer JSON",
                message: "El archivo JSON no tiene el formato correcto."
            )
        }
    }
    
    // MARK: - Helpers para alertas
    private func showSuccess(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    private func showError(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Preview
#Preview {
    ImportRecipeButton(viewModel: RecipeViewModel())
}
