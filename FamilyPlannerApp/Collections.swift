//
//  Collections.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import FirebaseFirestore

enum Collections {
    static let users = Firestore.firestore().collection("users")
    static let families = Firestore.firestore().collection("families")
}
