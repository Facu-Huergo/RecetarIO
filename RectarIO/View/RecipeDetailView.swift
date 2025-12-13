import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @ObservedObject var viewModel: RecipeViewModel
    
    @State private var multiplier: Double = 1.0
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    
    // Decodificar ingredientes desde el JSON guardado
    private var ingredients: [Ingredient] {
        guard let data = recipe.ingredients.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([Ingredient].self, from: data) else {
            return []
        }
        return decoded
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Encabezado con categoría y favorito
                HStack {
                    Text(recipe.category)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.toggleFavorite(recipe.id)
                    }) {
                        Image(systemName: viewModel.favorites.contains(recipe.id) ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(viewModel.favorites.contains(recipe.id) ? .red : .gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                Divider()
                
                // Sección de Ingredientes con Multiplicador
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Ingredientes")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Multiplicador
                        HStack(spacing: 8) {
                            Text("Porciones:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ForEach([1.0, 2.0, 3.0, 4.0, 5.0], id: \.self) { value in
                                Button(action: {
                                    multiplier = value
                                }) {
                                    Text("x\(Int(value))")
                                        .font(.subheadline)
                                        .fontWeight(multiplier == value ? .bold : .regular)
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 32)
                                        .background(multiplier == value ? Color.blue : Color.gray)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Lista de ingredientes con cantidades ajustadas
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(ingredients) { ingredient in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.blue)
                                    .padding(.top, 6)
                                
                                Text(ingredient.displayText(multiplier: multiplier))
                                    .font(.body)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Sección de Instrucciones
                VStack(alignment: .leading, spacing: 12) {
                    Text("Instrucciones")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(recipe.instructions)
                        .font(.body)
                        .lineSpacing(4)
                }
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.large)
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Botón de compartir
                    Button(action: shareRecipe) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    // Botón de editar
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRecipeView(recipe: recipe, viewModel: viewModel)
        }
        .sheet(isPresented: $showingShareSheet, onDismiss: {
            if let url = shareURL {
                try? FileManager.default.removeItem(at: url)
            }
        }) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func shareRecipe() {
        do {
            // 1. Codificar la receta a datos JSON
            let encoded = try JSONEncoder().encode(recipe)
            
            // 2. Crear una ruta de archivo temporal
            // Usamos un nombre de archivo único con extensión .json
            let safeTitle = recipe.title.replacingOccurrences(of: " ", with: "_").lowercased()
            let fileName = "\(safeTitle).json"
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            // 3. Escribir los datos JSON en el archivo
            try encoded.write(to: fileURL)
            
            // 4. Asignar la URL a la variable de estado.
            // Esto automáticamente activará el .sheet en el body.
            self.shareURL = fileURL
            self.showingShareSheet = true
            
        } catch {
            print("❌ Error al generar archivo para compartir: \(error)")
            self.shareURL = nil
        }
    }
}

// Preview
#Preview {
    NavigationView {
        RecipeDetailView(
            recipe: Recipe(
                title: "Pastel de Chocolate",
                category: "Postres",
                ingredients: """
                [{"id":"123","quantity":2.5,"unit":"Tazas","name":"Harina"},\
                {"id":"456","quantity":200,"unit":"ml","name":"Leche"},\
                {"id":"789","quantity":3,"unit":"Unid.","name":"Huevos"}]
                """,
                instructions: "1. Mezclar ingredientes secos\n2. Agregar líquidos\n3. Hornear a 180°C por 30 minutos"
            ),
            viewModel: RecipeViewModel()
        )
    }
}
