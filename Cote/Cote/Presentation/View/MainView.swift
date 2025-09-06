//
//  MainView.swift
//  Cote
//
//  Created by 김예림 on 7/26/25.
//

import SwiftUI
import AppKit

struct MainView: View {
    @State private var selectedButtonID: UUID?
    private let favoritesBarID = "com.example.favoritesBar"
    
    var body: some View {
        NavigationSplitView {
            ZStack {
                //블러 효과
                BlurEffect().ignoresSafeArea()
                Color.bgSidebar.ignoresSafeArea()
                
                Sidebar()
            }
            .toolbar(removing: .sidebarToggle)
            .toolbar(content: {
                ToolbarItem {
                    Spacer()
                }
                
                ToolbarItem(placement: .primaryAction, content: {
                    HStack(spacing: 4) {
                        Spacer()
                        ForEach (CoteIcon.toolbarIcons, id: \.id) { button in
                            MenuButton(selected: Binding(
                                get: { selectedButtonID == button.id },
                                set: { if $0 { selectedButtonID = button.id }}),
                                       icon: button
                            )
                        }
                    }
                })
            })
        } detail: {
            ZStack {
                Color.bgToolbar
                    .ignoresSafeArea(edges: .top)
                ContentView()
                    .environmentObject(ContentViewModel(initialContent: """
import PDFKit

class PDFAnnotationHandler {
    private var pdfView: PDFView
    
    init(view: PDFView) {
        self.pdfView = view
    }
    
    func addUnderline(to selection: PDFSelection) {
        let underline = PDFAnnotation(bounds: selection.bounds(for: pdfView.currentPage!),
                                      forType: .underline,
                                      withProperties: nil)
        pdfView.currentPage?.addAnnotation(underline)
    }
}
"""))
            }
        }
    }
}

#Preview {
    MainView()
}
