import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RecipeViewModel()
    @State private var showingAddRecipe = false
    @State private var selectedCategory: String = "Todas"
    @State private var showOnlyFavorites: Bool = false
    @State private var searchText: String = ""
    
    // Obtener todas las categorías únicas
    private var categories: [String] {
        var cats = Array(Set(viewModel.recipes.map { $0.category })).sorted()
        cats.insert("Todas", at: 0)
        return cats
    }
    
    // Filtrar y ordenar recetas
    private var filteredAndSortedRecipes: [Recipe] {
        var filtered = viewModel.recipes
        
        // Filtro por búsqueda
        if !searchText.isEmpty {
            filtered = filtered.filter { recipe in
                recipe.title.localizedCaseInsensitiveContains(searchText) ||
                recipe.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filtro por categoría
        if selectedCategory != "Todas" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filtro por favoritos
        if showOnlyFavorites {
            filtered = filtered.filter { viewModel.favorites.contains($0.id) }
        }
        
        // Ordenar: favoritos primero, luego por fecha de creación (más recientes primero)
        return filtered.sorted { recipe1, recipe2 in
            let isFav1 = viewModel.favorites.contains(recipe1.id)
            let isFav2 = viewModel.favorites.contains(recipe2.id)
            
            // Si uno es favorito y el otro no, el favorito va primero
            if isFav1 && !isFav2 {
                return true
            } else if !isFav1 && isFav2 {
                return false
            } else {
                // Si ambos son favoritos o ninguno lo es, ordenar por fecha
                return recipe1.dateCreated > recipe2.dateCreated
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Barra de búsqueda
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Buscar recetas...", text: $searchText)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Filtros
                HStack(spacing: 12) {
                    // Picker de categoría
                    Menu {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                HStack {
                                    Text(category)
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(selectedCategory)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    
                    // Botón de favoritos
                    Button(action: {
                        showOnlyFavorites.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: showOnlyFavorites ? "heart.fill" : "heart")
                            Text("Favoritos")
                        }
                        .font(.subheadline)
                        .fontWeight(showOnlyFavorites ? .semibold : .regular)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(showOnlyFavorites ? Color.red : Color(.systemGray5))
                        .foregroundColor(showOnlyFavorites ? .white : .primary)
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
                
                // Lista de recetas
                if filteredAndSortedRecipes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text(searchText.isEmpty ? "No hay recetas" : "No se encontraron recetas")
                            .font(.title3)
                            .foregroundColor(.gray)
                        
                        if !searchText.isEmpty || showOnlyFavorites || selectedCategory != "Todas" {
                            Button(action: {
                                searchText = ""
                                showOnlyFavorites = false
                                selectedCategory = "Todas"
                            }) {
                                Text("Limpiar filtros")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredAndSortedRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe, viewModel: viewModel)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(recipe.title)
                                            .font(.headline)
                                        
                                        HStack {
                                            Text(recipe.category)
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(8)
                                            
                                            if viewModel.favorites.contains(recipe.id) {
                                                Image(systemName: "heart.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Botón de favorito
                                    Button(action: {
                                        viewModel.toggleFavorite(recipe.id)
                                    }) {
                                        Image(systemName: viewModel.favorites.contains(recipe.id) ? "heart.fill" : "heart")
                                            .font(.title3)
                                            .foregroundColor(viewModel.favorites.contains(recipe.id) ? .red : .gray)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteRecipes)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Mis Recetas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ImportRecipeButton(viewModel: viewModel)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddRecipe = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeView(viewModel: viewModel)
            }
        }
    }
    
    private func deleteRecipes(at offsets: IndexSet) {
        let recipesToDelete = offsets.map { filteredAndSortedRecipes[$0] }
        for recipe in recipesToDelete {
            if let index = viewModel.recipes.firstIndex(where: { $0.id == recipe.id }) {
                viewModel.recipes.remove(at: index)
            }
        }
        viewModel.saveRecipes()
    }
}

// Preview
#Preview {
    ContentView()
}
