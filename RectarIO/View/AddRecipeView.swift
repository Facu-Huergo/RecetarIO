import SwiftUI

// Modelo para un ingrediente individual
struct Ingredient: Identifiable, Codable {
    var id = UUID()
    var quantity: Double  // Cambiado a Double para poder multiplicar
    var unit: String
    var name: String
    
    func displayText(multiplier: Double = 1.0) -> String {
        let adjustedQuantity = quantity * multiplier
        // Formatear el número (eliminar decimales innecesarios)
        let formattedQuantity: String
        if adjustedQuantity.truncatingRemainder(dividingBy: 1) == 0 {
            formattedQuantity = String(format: "%.0f", adjustedQuantity)
        } else {
            formattedQuantity = String(format: "%.2f", adjustedQuantity)
        }
        
        return "\(formattedQuantity) \(unit) - \(name)"
    }
}

// Enum para tipos de medida
enum MeasurementType: String, CaseIterable {
    case cups = "Tazas"
    case ml = "ml"
    case grams = "gr"
    case tablespoons = "Cdas"
    case teaspoons = "Cditas"
    case units = "Unid."
    case kg = "kg"
    case liters = "L"
}

struct AddRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: RecipeViewModel
    
    @State private var title = ""
    @State private var category = ""
    @State private var instructions = ""
    
    // Estados para agregar ingredientes
    @State private var ingredients: [Ingredient] = []
    @State private var currentQuantity = ""
    @State private var selectedUnit: MeasurementType = .cups
    @State private var currentIngredientName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información de la receta")) {
                    TextField("Título", text: $title)
                    TextField("Categoría (ej: Postres, Platos principales)", text: $category)
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
            .navigationTitle("Nueva Receta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveRecipe()
                    }
                    .disabled(title.isEmpty || category.isEmpty || ingredients.isEmpty || instructions.isEmpty)
                }
            }
        }
    }
    
    private func addIngredient() {
        // Validar y convertir la cantidad a Double
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
    
    private func saveRecipe() {
        // Codificar la lista de ingredientes como JSON
        if let ingredientsData = try? JSONEncoder().encode(ingredients),
           let ingredientsString = String(data: ingredientsData, encoding: .utf8) {
            
            let newRecipe = Recipe(
                title: title,
                category: category,
                ingredients: ingredientsString,
                instructions: instructions
            )
            
            viewModel.addRecipe(newRecipe)
            dismiss()
        }
    }
}

// Preview
#Preview {
    AddRecipeView(viewModel: RecipeViewModel())
}
