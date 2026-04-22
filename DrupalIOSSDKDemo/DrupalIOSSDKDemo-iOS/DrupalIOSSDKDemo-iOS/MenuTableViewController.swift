//
//  MenuTableViewController.swift
//  DrupalIOSSDKDemo-iOS
//

import UIKit
import DrupalIOSSDK
import DrupalIOSSDKUI

enum TableViewRows: String, CaseIterable {
    case authentication = "Authentication"
    case views          = "Views"
}

/// Row shape returned by our demo Drupal View's REST export.
/// Replace the field names to match your site's View fields.
public struct FrontpageViewContent: Decodable {
    public let title: String?
    public let body: String?
    public let contentType: String?
    public let date: String?
    public let image: String?

    enum CodingKeys: String, CodingKey {
        case title, body
        case contentType = "type"
        case date = "created"
        case image = "field_image"
    }
}

final class ExampleCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MenuTableViewController: UITableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        TableViewRows.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = TableViewRows.allCases[indexPath.row].rawValue
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        switch TableViewRows.allCases[indexPath.row] {
        case .authentication:
            let loginVc = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            navigationController?.pushViewController(loginVc, animated: true)
        case .views:
            let frontpageVC = DrupalViewTableViewController<FrontpageViewContent, ExampleCell>(
                viewPath: "frontpage",
                configure: { cell, row in
                    cell.textLabel?.text = row.title
                    cell.detailTextLabel?.text = row.contentType
                }
            )
            frontpageVC.title = "Frontpage"
            frontpageVC.didSelect = { [weak self] selection in
                let nodeVC = storyboard.instantiateViewController(withIdentifier: "NodeViewController") as! NodeViewController
                nodeVC.object = selection
                self?.navigationController?.pushViewController(nodeVC, animated: true)
            }
            navigationController?.pushViewController(frontpageVC, animated: true)
        }
    }
}
