//
//  AuthServicing.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import Foundation
import UIKit

@MainActor
protocol AuthServicing {
    var currentUID: String? { get }
    var currentEmail: String? { get }
    var providerIDs: [String] { get }
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String) async throws -> String
    func signOut() throws
    func signInWithApple(nonce: String) async throws
    func signInWithGoogle(presenting: UIViewController) async throws
}
