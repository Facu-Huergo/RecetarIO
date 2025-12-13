import Foundation
import Combine


class RecipeViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var favorites: Set<UUID> = []
    
    init() {
        loadRecipes()
        loadFavorites()
    }
    
    func addRecipe(_ recipe: Recipe) {
        recipes.append(recipe)
        saveRecipes()
    }
    
    func updateRecipe(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
            saveRecipes()
        }
    }
    
    func toggleFavorite(_ recipeId: UUID) {
        if favorites.contains(recipeId) {
            favorites.remove(recipeId)
        } else {
            favorites.insert(recipeId)
        }
        saveFavorites()
    }
    
    func saveRecipes() {
        if let encoded = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(encoded, forKey: "recipes")
        }
    }
    
    private func loadRecipes() {
        if let data = UserDefaults.standard.data(forKey: "recipes"),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
            recipes = decoded
        }
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(Array(favorites)) {
            UserDefaults.standard.set(encoded, forKey: "favorites")
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "favorites"),
           let decoded = try? JSONDecoder().decode([UUID].self, from: data) {
            favorites = Set(decoded)
        }
    }
    
    func exportRecipe(_ recipe: Recipe) -> URL? {
        guard let encoded = try? JSONEncoder().encode(recipe) else {
            return nil
        }
        
        // Convertir a Base64 para evitar problemas de formato
        let base64String = encoded.base64EncodedString()
        
        let content = ""
        
        let fileName = "\(recipe.title.replacingOccurrences(of: " ", with: "_"))_receta.txt"
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error al exportar: \(error)")
            return nil
        }
    }
    
    // Función auxiliar para formatear ingredientes
    private func formatIngredients(_ ingredientsJSON: String) -> String {
        guard let data = ingredientsJSON.data(using: .utf8),
              let ingredients = try? JSONDecoder().decode([Ingredient].self, from: data) else {
            return "No disponible"
        }
        
        return ingredients.map { "• \($0.displayText())" }.joined(separator: "\n")
    }
    
    func importRecipe(from url: URL) -> Bool {
        // 1. Solicitar permiso de seguridad para leer el archivo
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            // 2. Leer los datos directamente del archivo
            let data = try Data(contentsOf: url)
            
            // 3. Decodificar el JSON a tu estructura Recipe
            var importedRecipe = try JSONDecoder().decode(Recipe.self, from: data)
            
            // 4. Asignar un nuevo ID y fecha para evitar duplicados exactos de sistema
            importedRecipe.id = UUID()
            importedRecipe.dateCreated = Date()
            
            // 5. Agregar a la lista y guardar
            // Verificamos que no exista ya una receta con el mismo título para no duplicar visualmente (opcional)
            if !recipes.contains(where: { $0.title == importedRecipe.title && $0.instructions == importedRecipe.instructions }) {
                recipes.append(importedRecipe)
                saveRecipes()
                print("✅ Receta importada: \(importedRecipe.title)")
                return true
            } else {
                print("⚠️ La receta ya existe")
                return true // Devolvemos true porque técnicamente se leyó bien, aunque no se agregó
            }
            
        } catch {
            print("❌ Error al importar: \(error.localizedDescription)")
            return false
        }
    }
}
