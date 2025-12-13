import Foundation

struct Recipe: Identifiable, Codable {
    var id = UUID()
    var title: String
    var category: String
    var ingredients: String
    var instructions: String
    var dateCreated: Date = Date()
    
    // Asegúrate de tener este inicializador completo
    init(id: UUID = UUID(), title: String, category: String, ingredients: String, instructions: String, dateCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.category = category
        self.ingredients = ingredients
        self.instructions = instructions
        self.dateCreated = dateCreated
    }
}
