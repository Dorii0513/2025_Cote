//
//  ContentView.swift
//  Cote
//
//  Created by 김예림 on 6/17/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.bgInputDefault
            
            VStack {
                Text("Untitled")
                
                Button {
                    
                } label: {
                    Text("Add tags")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
