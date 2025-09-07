//
//  MainView.swift
//  Cote
//
//  Created by 김예림 on 7/26/25.
//

import SwiftUI
import AppKit

struct MainView: View {
    @State private var window: NSWindow?
    
    var body: some View {
        NavigationSplitView {
            ZStack {
                
                //블러 효과
                BlurEffect().ignoresSafeArea()
                Color.bgSidebar.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Toolbar()
                    Sidebar()
                }
                .ignoresSafeArea()
            }
            .toolbar(removing: .sidebarToggle)
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

//MARK: - 사이드바
private struct Sidebar: View {
    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.actionDefault)
                FolderView()
            }
        }
        .frame(minWidth: 210, minHeight: 700)
        .background(Color.clear)
    }
}

//MARK: - content


#Preview {
    MainView()
}
