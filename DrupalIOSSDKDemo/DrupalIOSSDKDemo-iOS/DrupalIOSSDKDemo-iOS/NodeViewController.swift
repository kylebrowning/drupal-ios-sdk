//
//  NodeViewController.swift
//  DrupalIOSSDKDemo-iOS
//

import UIKit
import DrupalIOSSDK

open class NodeViewController: UIViewController {

    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var textViewBody: UITextView!
    @IBOutlet weak var imageView: UIImageView!

    open var object: FrontpageViewContent!

    override open func viewDidLoad() {
        super.viewDidLoad()
        labelTitle.text = object.title
        labelDate.text = object.date
        textViewBody.text = object.body
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let base = Drupal.shared.baseURL,
              let relativeImagePath = object.image,
              let imageURL = URL(string: relativeImagePath, relativeTo: base) else {
            return
        }
        Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                if let image = UIImage(data: data) {
                    await MainActor.run { self?.imageView.image = image }
                }
            } catch {
                print("failed to load image:", error.localizedDescription)
            }
        }
    }
}
