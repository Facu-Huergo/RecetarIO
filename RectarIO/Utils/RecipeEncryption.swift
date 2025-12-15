import Foundation
import CryptoKit

// MARK: - Gestión de Encriptación de Recetas
class RecipeEncryption {
    
    // Clave simétrica para encriptar/desencriptar
    private static let encryptionKey = "RecetarIO2025Key"
    
    // MARK: - Encriptar Receta
    /// Convierte una receta a JSON encriptado
    static func encrypt(recipe: Recipe) -> Data? {
        do {
            // 1. Codificar la receta a JSON
            let jsonData = try JSONEncoder().encode(recipe)
            
            // 2. Crear una clave simétrica desde nuestra string
            let keyData = Data(encryptionKey.utf8)
            let hashedKey = SHA256.hash(data: keyData)
            let symmetricKey = SymmetricKey(data: hashedKey)
            
            // 3. Encriptar usando AES-GCM (Galois/Counter Mode)
            let sealedBox = try AES.GCM.seal(jsonData, using: symmetricKey)
            
            // 4. Retornar los datos encriptados combinados
            return sealedBox.combined
            
        } catch {
            print("❌ Error al encriptar: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Desencriptar Receta
    /// Convierte datos encriptados de vuelta a una receta
    static func decrypt(data: Data) -> Recipe? {
        do {
            // 1. Recrear la clave simétrica
            let keyData = Data(encryptionKey.utf8)
            let hashedKey = SHA256.hash(data: keyData)
            let symmetricKey = SymmetricKey(data: hashedKey)
            
            // 2. Crear el sealed box desde los datos
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            
            // 3. Desencriptar
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            
            // 4. Decodificar el JSON a Recipe
            let recipe = try JSONDecoder().decode(Recipe.self, from: decryptedData)
            
            return recipe
            
        } catch {
            print("❌ Error al desencriptar: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Validar Archivo .rio
    /// Verifica si un archivo tiene formato válido de RecetarIO
    static func isValidRIOFile(data: Data) -> Bool {
        return decrypt(data: data) != nil
    }
    
    // MARK: - Crear archivo .rio
    /// Exporta una receta a un archivo .rio encriptado
    static func exportToRIO(recipe: Recipe) -> URL? {
        print("🔐 Iniciando encriptación de: \(recipe.title)")
        
        guard let encryptedData = encrypt(recipe: recipe) else {
            print("❌ No se pudo encriptar la receta")
            return nil
        }
        
        print("✅ Datos encriptados: \(encryptedData.count) bytes")
        
        // Crear nombre de archivo seguro (sin caracteres especiales)
        let safeTitle = recipe.title
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "*", with: "-")
            .replacingOccurrences(of: "?", with: "-")
            .replacingOccurrences(of: "\"", with: "-")
            .replacingOccurrences(of: "<", with: "-")
            .replacingOccurrences(of: ">", with: "-")
            .replacingOccurrences(of: "|", with: "-")
            .lowercased()
        
        let fileName = "\(safeTitle).rio"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        print("📁 Intentando escribir en: \(fileURL.path)")
        
        do {
            // Eliminar archivo anterior si existe
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("🗑️ Archivo anterior eliminado")
            }
            
            // Escribir nuevo archivo
            try encryptedData.write(to: fileURL, options: .atomic)
            
            // Verificar que se escribió correctamente
            let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int ?? 0
            print("✅ Archivo .rio creado exitosamente")
            print("   Nombre: \(fileName)")
            print("   Tamaño: \(fileSize) bytes")
            print("   Ubicación: \(fileURL.path)")
            
            return fileURL
            
        } catch {
            print("❌ Error al escribir archivo: \(error.localizedDescription)")
            print("   Error detallado: \(error)")
            return nil
        }
    }
    
    // MARK: - Importar desde .rio
    /// Lee un archivo .rio y devuelve la receta desencriptada
    static func importFromRIO(url: URL) -> Recipe? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            // Validar y desencriptar
            guard let recipe = decrypt(data: data) else {
                print("❌ El archivo no es un .rio válido o está corrupto")
                return nil
            }
            
            print("✅ Receta importada: \(recipe.title)")
            return recipe
            
        } catch {
            print("❌ Error al leer archivo: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Extensión para info del archivo
extension RecipeEncryption {
    
    /// Información sobre el formato .rio
    static var fileInfo: String {
        """
        📦 Formato RecetarIO (.rio)
        
        • Extensión: .rio
        • Tipo: Receta encriptada
        • Encriptación: AES-256-GCM
        • Compatible: RecetarIO v1.0+
        
        Los archivos .rio son seguros y solo pueden
        ser leídos por la aplicación RecetarIO.
        """
    }
}
