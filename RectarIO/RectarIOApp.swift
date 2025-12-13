//
//  RectarIOApp.swift
//  RectarIO
//
//  Created by Facundo Huergo on 09/11/2025.
//

import SwiftUI
import CoreData
@main
struct RectarIOApp: App {
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
