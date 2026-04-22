//
//  waterwheelViewTableViewController.swift
//  Waterwheel 5.x — iOS only.
//

#if os(iOS)
import UIKit

/// Default row shape produced by a Drupal View's REST export. Most views will
/// need their own `Decodable` row type — provide one to
/// ``waterwheelViewTableViewController`` via its generic `Row` parameter.
public struct ViewResponseRow: Decodable {
    public let title: String?
    public let body: String?
}

@available(iOS 15.0, *)
open class waterwheelViewTableViewController<Row: Decodable, Cell: UITableViewCell>: UITableViewController {

    public var rows: [Row] = []
    public let reuseIdentifier = "Cell"
    public let configure: (Cell, Row) -> Void
    public var didSelect: (Row) -> Void = { _ in }
    public var didFinish: ([Row], waterwheelViewTableViewController) -> Void = { _, _ in }

    public init(items: [Row], configure: @escaping (Cell, Row) -> Void) {
        self.configure = configure
        super.init(style: .plain)
        self.rows = items
    }

    public convenience init(viewPath: String, configure: @escaping (Cell, Row) -> Void) {
        self.init(items: [], configure: configure)
        Task { @MainActor in
            do {
                let data = try await Waterwheel.shared.view(at: viewPath)
                let items = try JSONDecoder().decode([Row].self, from: data)
                self.rows = items
                self.tableView.reloadData()
                self.didFinish(items, self)
            } catch {
                print("waterwheel error fetching view: \(error.localizedDescription)")
                self.didFinish([], self)
            }
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(Cell.self, forCellReuseIdentifier: reuseIdentifier)
    }

    // MARK: - UITableViewDataSource / Delegate

    override open func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelect(rows[indexPath.row])
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! Cell
        configure(cell, rows[indexPath.row])
        return cell
    }
}

#endif
