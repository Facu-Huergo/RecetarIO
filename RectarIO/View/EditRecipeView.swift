
import SwiftUI

struct EditRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: RecipeViewModel
    let recipe: Recipe
    
    @State private var title: String
    @State private var category: String
    @State private var instructions: String
    @State private var ingredients: [Ingredient]
    
    // Estados para agregar ingredientes
    @State private var currentQuantity = ""
    @State private var selectedUnit: MeasurementType = .cups
    @State private var currentIngredientName = ""
    
    // Inicializador que carga los datos de la receta existente
    init(recipe: Recipe, viewModel: RecipeViewModel) {
        self.recipe = recipe
        self.viewModel = viewModel
        
        // Inicializar con los datos existentes
        _title = State(initialValue: recipe.title)
        _category = State(initialValue: recipe.category)
        _instructions = State(initialValue: recipe.instructions)
        
        // Decodificar ingredientes
        if let data = recipe.ingredients.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([Ingredient].self, from: data) {
            _ingredients = State(initialValue: decoded)
        } else {
            _ingredients = State(initialValue: [])
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información de la receta")) {
                    TextField("Título", text: $title)
                    TextField("Categoría", text: $category)
                }
                
                Section(header: Text("Ingredientes")) {
                    // Selector de tipo de medida
                    Picker("Tipo de medida", selection: $selectedUnit) {
                        ForEach(MeasurementType.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    // Input unificado con decimales
                    HStack(spacing: 12) {
                        TextField("Cant.", text: $currentQuantity)
                            .keyboardType(.decimalPad)
                            .frame(width: 70)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text(selectedUnit.rawValue)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        TextField("Ingrediente", text: $currentIngredientName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Button(action: addIngredient) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Agregar ingrediente")
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(currentIngredientName.isEmpty || currentQuantity.isEmpty)
                    
                    // Lista de ingredientes agregados
                    if !ingredients.isEmpty {
                        ForEach(ingredients) { ingredient in
                            HStack {
                                Text(ingredient.displayText())
                                    .font(.body)
                                Spacer()
                                Button(action: {
                                    removeIngredient(ingredient)
                                }) {
                                    Image(systemName: "trash.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Instrucciones")) {
                    TextEditor(text: $instructions)
                        .frame(height: 150)
                }
            }
            .navigationTitle("Editar Receta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        updateRecipe()
                    }
                    .disabled(title.isEmpty || category.isEmpty || ingredients.isEmpty || instructions.isEmpty)
                }
            }
        }
    }
    
    private func addIngredient() {
        let cleanedQuantity = currentQuantity.replacingOccurrences(of: ",", with: ".")
        guard let quantity = Double(cleanedQuantity) else {
            return
        }
        
        let ingredient = Ingredient(
            quantity: quantity,
            unit: selectedUnit.rawValue,
            name: currentIngredientName
        )
        
        ingredients.append(ingredient)
        
        // Limpiar campos
        currentQuantity = ""
        currentIngredientName = ""
    }
    
    private func removeIngredient(_ ingredient: Ingredient) {
        ingredients.removeAll { $0.id == ingredient.id }
    }
    
    private func updateRecipe() {
        // Codificar la lista de ingredientes como JSON
        if let ingredientsData = try? JSONEncoder().encode(ingredients),
           let ingredientsString = String(data: ingredientsData, encoding: .utf8) {
            
            let updatedRecipe = Recipe(
                id: recipe.id,  // Mantener el mismo ID
                title: title,
                category: category,
                ingredients: ingredientsString,
                instructions: instructions,
                dateCreated: recipe.dateCreated  // Mantener la fecha original
            )
            
            viewModel.updateRecipe(updatedRecipe)
            dismiss()
        }
    }
}

// Preview
#Preview {
    EditRecipeView(
        recipe: Recipe(
            title: "Pastel de Chocolate",
            category: "Postres",
            ingredients: """
            [{"id":"123","quantity":2.5,"unit":"Tazas","name":"Harina"}]
            """,
            instructions: "Mezclar y hornear"
        ),
        viewModel: RecipeViewModel()
    )
}
