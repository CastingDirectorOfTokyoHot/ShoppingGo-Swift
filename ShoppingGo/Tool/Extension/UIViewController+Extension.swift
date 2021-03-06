//
//  UIViewController+Extension.swift
//  ShoppingGo
//
//  Created by 杜进新 on 2017/7/14.
//  Copyright © 2017年 杜进新. All rights reserved.
//

import UIKit

extension UIViewController {
    /// 获取当前栈顶控制器
    var topStackViewController: UIViewController? {
        guard let rootVc = UIApplication.shared.keyWindow?.rootViewController else {
            return nil
        }
        if rootVc is UITabBarController {
            let vc = rootVc as! UITabBarController
            if vc.selectedViewController is UINavigationController {
                let selectVC = vc.selectedViewController as! UINavigationController
                let topVC = selectVC.topViewController
                return topVC
            }else{
                return vc.selectedViewController
            }
        }else if rootVc is UINavigationController{
            let vc = rootVc as! UINavigationController
            let topVC = vc.topViewController
            return topVC
        }else{
            return rootVc
        }
    }
    /// 获取当前显示的控制器，包括模态视图
    var topVisibleViewController: UIViewController? {
        
        guard let topVC = self.topStackViewController else {
            return nil
        }
        if topVC is UINavigationController {
            let vc = topVC as! UINavigationController
            return vc.visibleViewController
        }else{
            if let presentedVC = topVC.presentedViewController {
                return presentedVC
            }
            return topVC
        }
    }
}
