//
//  NewFamilySheet.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/12/25.
//

import SwiftUI

struct NewFamilySheet: View {
    @Binding var name: String
    
    let isCreating: Bool
    let onCancel: () -> Void
    let onCreate: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Household name") {
                    TextField("e.g. The Johnsons", text: $name)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }
            }
            .navigationTitle("New Household")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel, action: onCancel)
                        .disabled(isCreating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onCreate()
                    } label: {
                        if isCreating {
                            ProgressView()
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(isCreating || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .interactiveDismissDisabled(isCreating) // avoid dismiss while creating
    }
}

#Preview {
    NewFamilySheet(name: .constant("Toby's Household"), isCreating: false, onCancel: {}, onCreate: {})
}
