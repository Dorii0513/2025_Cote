//
//  ChatView.swift
//  Cote
//
//  Created by 김예림 on 11/16/25.
//

import SwiftUI

//@available(macOS 26.0, *)
struct ChatView: View {
    @State var message: String
//    @EnvironmentObject private var viewModel: ChatViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer()
            HStack {
                Button {
                    
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles.2")
                            .foregroundStyle(.iconDefault)
                        Text("Generate Comments")
                            .coteFont(.text2, color: .textDefault)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.actionDefault)
                    )
                }
                .buttonStyle(.plain)
                
                Button {
                    
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles.2")
                            .foregroundStyle(.iconDefault)
                        Text("Generate Tags")
                            .coteFont(.text2, color: .textDefault)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.actionDefault)
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            
            HStack {
                TextField("", text: $message)
                    .coteFont(.text2, color: .textSelected)
                    .tint(.textDefault)
                    .textFieldStyle(.plain)
                    .padding(.leading, 6)
                
                Spacer()
                
                Button {
                    
                } label: {
                    Image("arrow_up")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.textTag)
                        
//                        .padding(3)
                }
                .buttonStyle(.plain)
            }
            .padding([.vertical, .horizontal], 5)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(.bgTextField)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(.textTag.opacity(0.5), lineWidth: 2)
                            .shadow(color: .textTag, radius: 5)
                    )
            )
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 15)
    }
}

#Preview {
    ChatView(message: "zz")
}
