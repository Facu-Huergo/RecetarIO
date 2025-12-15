import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        print("📤 Creando UIActivityViewController")
        print("📦 Items a compartir: \(items.count)")
        
        // Verificar que los items sean válidos
        for (index, item) in items.enumerated() {
            if let url = item as? URL {
                print("  - Item \(index): URL = \(url.lastPathComponent)")
                print("    Existe: \(FileManager.default.fileExists(atPath: url.path))")
            } else if let string = item as? String {
                print("  - Item \(index): String = \(string.prefix(50))...")
            } else {
                print("  - Item \(index): Tipo = \(type(of: item))")
            }
        }
        
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Configuración adicional para iPad
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView()
            popover.permittedArrowDirections = []
        }
        
        // Excluir algunas actividades si lo deseas (opcional)
        // controller.excludedActivityTypes = [.addToReadingList, .assignToContact]
        
        print("✅ UIActivityViewController creado exitosamente")
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No necesitamos actualizar nada
    }
}
