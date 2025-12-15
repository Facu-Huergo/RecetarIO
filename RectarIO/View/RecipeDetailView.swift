import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @ObservedObject var viewModel: RecipeViewModel
    
    @State private var multiplier: Double = 1.0
    @State private var showingEditSheet = false
    
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
                    // Botón de compartir - DIRECTO
                    Button(action: shareRecipeDirectly) {
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
    }
    
    // MARK: - 🔒 Compartir Receta DIRECTO
    private func shareRecipeDirectly() {
        print("🔄 Iniciando compartir directo...")
        
        // 1. Crear archivo .rio
        guard let fileURL = viewModel.exportRecipe(recipe) else {
            print("❌ Error al generar archivo .rio")
            return
        }
        
        print("✅ Archivo creado: \(fileURL.lastPathComponent)")
        print("📍 Path: \(fileURL.path)")
        
        // 2. Verificar existencia
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("❌ El archivo no existe")
            return
        }
        
        // 3. Obtener el rootViewController
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            print("❌ No se pudo obtener el rootViewController")
            return
        }
        
        // 4. Encontrar el viewController presentado (si hay navegación)
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        
        print("📱 ViewController encontrado: \(type(of: topVC))")
        
        // 5. Crear mensaje y items
        let message = "¡Te comparto mi receta de \(recipe.title)! 👨‍🍳\n\nÁbrela con RecetarIO"
        let items: [Any] = [message, fileURL]
        
        print("📦 Items a compartir: \(items.count)")
        print("   - Mensaje: \(message.prefix(50))...")
        print("   - Archivo: \(fileURL.lastPathComponent)")
        
        // 6. Crear UIActivityViewController
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // 7. Configuración para iPad (popover)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        // 8. Callback de completado
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            
            // Limpiar archivo temporal
            try? FileManager.default.removeItem(at: fileURL)
            
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
            } else if completed {
                print("✅ Compartido vía: \(activityType?.rawValue ?? "unknown")")
            } else {
                print("ℹ️ Usuario canceló")
            }
        }
        
        // 9. Presentar con delay para asegurar que la UI esté lista
        DispatchQueue.main.async {
            print("📤 Presentando ActivityViewController...")
            topVC.present(activityVC, animated: true) {
                print("✅ ActivityViewController presentado correctamente")
            }
        }
    }
}

// MARK: - Preview
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
