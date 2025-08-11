//
//  HomeSessionReadable.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

protocol HomeSessionReadable {
    var homeDisplayName: String? { get }
    var homeEmail: String? { get }
    var homeUserId: String? { get }
    var homeFamilyId: String? { get }
    var homeFamilyName: String? { get }
}
