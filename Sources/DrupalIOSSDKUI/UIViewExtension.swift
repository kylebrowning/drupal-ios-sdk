//
//  UIViewExtension.swift
//  DrupalIOSSDKUI
//

#if os(iOS)
import UIKit

@available(iOS 15.0, *)
extension UIView {
    public func constrainEqual(_ attribute: NSLayoutConstraint.Attribute,
                               to: AnyObject,
                               multiplier: CGFloat = 1,
                               constant: CGFloat = 0) {
        constrainEqual(attribute, to: to, attribute, multiplier: multiplier, constant: constant)
    }

    public func constrainEqual(_ attribute: NSLayoutConstraint.Attribute,
                               to: AnyObject,
                               _ toAttribute: NSLayoutConstraint.Attribute,
                               multiplier: CGFloat = 1,
                               constant: CGFloat = 0) {
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: self,
                               attribute: attribute,
                               relatedBy: .equal,
                               toItem: to,
                               attribute: toAttribute,
                               multiplier: multiplier,
                               constant: constant)
        ])
    }

    public func constrainEdges(to view: UIView) {
        constrainEqual(.top, to: view, .top)
        constrainEqual(.leading, to: view, .leading)
        constrainEqual(.trailing, to: view, .trailing)
        constrainEqual(.bottom, to: view, .bottom)
    }
}

#endif
