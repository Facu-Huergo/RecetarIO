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
    
    // MARK: - 🔒 EXPORTAR con Encriptación (.rio)
    func exportRecipe(_ recipe: Recipe) -> URL? {
        return RecipeEncryption.exportToRIO(recipe: recipe)
    }
    
    // MARK: - 🔓 IMPORTAR desde .rio encriptado
    func importRecipe(from url: URL) -> Bool {
        // 1. Intentar desencriptar el archivo .rio
        guard let importedRecipe = RecipeEncryption.importFromRIO(url: url) else {
            print("❌ No se pudo importar: archivo inválido o corrupto")
            return false
        }
        
        // 2. Asignar nuevo ID y fecha para evitar conflictos
        var recipeToAdd = importedRecipe
        recipeToAdd.id = UUID()
        recipeToAdd.dateCreated = Date()
        
        // 3. Verificar si ya existe (opcional)
        let alreadyExists = recipes.contains { existingRecipe in
            existingRecipe.title == recipeToAdd.title &&
            existingRecipe.ingredients == recipeToAdd.ingredients &&
            existingRecipe.instructions == recipeToAdd.instructions
        }
        
        if alreadyExists {
            print("⚠️ La receta '\(recipeToAdd.title)' ya existe")
        }
        
        // 4. Agregar y guardar
        recipes.append(recipeToAdd)
        saveRecipes()
        
        print("✅ Receta '\(recipeToAdd.title)' importada exitosamente")
        return true
    }
    
    // MARK: - 📊 Estadísticas (opcional)
    var totalRecipes: Int { recipes.count }
    var totalFavorites: Int { favorites.count }
    
    func recipesByCategory() -> [String: Int] {
        Dictionary(grouping: recipes, by: { $0.category })
            .mapValues { $0.count }
    }
}
