//
//  DrupalViewList.swift
//  DrupalIOSSDKUI — a SwiftUI list that streams rows from a Drupal View's
//  REST export using the injected ``DrupalClient``.
//

#if canImport(SwiftUI)
import SwiftUI
import DrupalIOSSDK

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct DrupalViewList<Row: Decodable & Identifiable, RowView: View>: View {

    @Environment(\.drupal) private var drupal

    @State private var rows: [Row] = []
    @State private var errorMessage: String?
    @State private var isLoading: Bool = true

    private let viewPath: String
    private let query: [String: String]
    private let rowView: (Row) -> RowView

    public init(
        viewPath: String,
        query: [String: String] = [:],
        @ViewBuilder rowView: @escaping (Row) -> RowView
    ) {
        self.viewPath = viewPath
        self.query = query
        self.rowView = rowView
    }

    public var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading…")
            } else if let errorMessage {
                VStack(spacing: 8) {
                    Text("Couldn't load \(viewPath).").font(.headline)
                    Text(errorMessage).foregroundStyle(.secondary)
                    Button("Retry") { Task { await reload() } }
                }
                .padding()
            } else {
                List(rows, rowContent: rowView)
            }
        }
        .task { await reload() }
    }

    @MainActor
    private func reload() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let data = try await drupal.view(viewPath, query)
            rows = try JSONDecoder().decode([Row].self, from: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
#endif
