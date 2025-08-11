//
//  ToastView.swift
//  FamilyPlannerApp
//
//  Created by Toby Gamble on 8/10/25.
//

import SwiftUI

struct ToastView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .padding(8)
            .background(.red.opacity(0.95))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding()
     }
}

#Preview {
    ToastView(text: "Hello World!")
}
