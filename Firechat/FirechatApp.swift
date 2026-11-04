//
//  FirechatApp.swift
//  Firechat
//
//  Created by Ritch Barlatier on 10/28/26.
//
import FirebaseCore
import SwiftUI

@main
struct FireChatApp: App {

    init() { // <-- Add an init
        FirebaseApp.configure() // <-- Configure Firebase app
    }

    var body: some Scene {
        WindowGroup {
            TranslationMeView()
        }
    }
}
