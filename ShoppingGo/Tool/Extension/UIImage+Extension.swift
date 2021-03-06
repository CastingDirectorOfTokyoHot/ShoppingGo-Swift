
//
//  UIImage+Extension.swift
//  ZPOperator
//
//  Created by 杜进新 on 2017/7/1.
//  Copyright © 2017年 dujinxin. All rights reserved.
//

import UIKit
import Photos

extension UIImage {
    
    /// 依据宽度等比例对图片重新绘制
    ///
    /// - Parameters:
    ///   - originalImage: 原图
    ///   - scaledWidth: 将要缩放或拉伸的宽度
    /// - Returns: 新的图片
    class func image(originalImage:UIImage? ,to scaledWidth:CGFloat) -> UIImage? {
        guard let image = originalImage else {
            return UIImage.init()
        }
        let imageWidth = image.size.width
        let imageHeigth = image.size.height
        let width = scaledWidth
        let height = image.size.height / (image.size.width / width)
        
        let widthScale = imageWidth / width
        let heightScale = imageHeigth / height
        
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        
        if widthScale > heightScale {
            image.draw(in: CGRect(x: 0, y: 0, width: imageWidth / heightScale, height: heightScale))
        } else {
            image.draw(in: CGRect(x: 0, y: 0, width: width, height: imageHeigth / widthScale))
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    static func image(originalImage:UIImage?,rect:CGRect,radius:CGFloat) -> UIImage? {
        guard let image = originalImage else {
            return UIImage.init()
        }
        //opaque 是否透明 false透明 true不透明
        //scale 绘制分辨率，默认为1.0,会模糊，设置为0会自动根据屏幕分辨率来绘制
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        
        
        //let path = UIBezierPath(arcCenter: self.center, radius: radius, startAngle: pid_t * 0, endAngle: pid_t * 2, clockwise: true)
        //let path = UIBezierPath(ovalIn: rect)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        //剪切
        path.addClip()
        
        image.draw(in: rect)
        
        //path.lineCapStyle = .round
        UIColor.groupTableViewBackground.setStroke()
        path.lineWidth = 3
        //path.stroke(with: .color, alpha: 0.8)
        path.stroke()
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        
        return newImage
    }
    static func imageScreenshot(view: UIView) -> UIImage? {
        let rect = view.bounds
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        view.layer.render(in: context!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
}
//MARK:保存图片到相册
extension UIImage {
    
    
    class func save(image:UIImage,completion:((_ isSuccess:Bool)->())?) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
    }
    func image(image:UIImage,didFinishSavingWithError error:Error?,contextInfo:AnyObject?) {
        if error != nil {
            //
            print("保存成功")
        }else{
            print("保存失败")
        }
    }
    
    class func saveImage(image:UIImage,isAlbum:Bool = false,completion:@escaping ((_ isSuccess:Bool,_ msg:String)->())) -> Void {
        
        //let isGo = authorizationStatus()
        
        saveImageToAlbum(image: image, isCreateAlbum: isAlbum, albumName: "操作员", completion: completion)

    }
    private func authorizationStatus() -> Bool {
        if PHPhotoLibrary.authorizationStatus() == .authorized{
            return true
        }else{
            return false
        }
//        PHPhotoLibrary.requestAuthorization({ (status) in
//            if status == .authorized {
//                
//            }
//        })
    }
    class private func saveImageToAlbum(image:UIImage,isCreateAlbum:Bool,albumName:String,completion:@escaping ((_ isSuccess:Bool,_ msg:String)->())) -> Void {
        //同步执行
//        try? PHPhotoLibrary.shared().performChangesAndWait({
//            //
//            PHAssetChangeRequest.creationRequestForAsset(from: cell.imageView.image!)
//        })
        //异步
        var placeHolder : String!
        PHPhotoLibrary.shared().performChanges({
            //
            let changeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            placeHolder = changeRequest.placeholderForCreatedAsset?.localIdentifier
            
        }, completionHandler: { (isSuccess, error) in
            //
            if isCreateAlbum == false{
                completion(isSuccess,"保存成功")
                return
            }
            if isSuccess{
                let phassetResults = PHAsset.fetchAssets(withLocalIdentifiers: [placeHolder], options: nil)
                //print(phassetResults.firstObject)
                
                var collectionChangeRequest: PHAssetCollectionChangeRequest!
                var phAssetCollection : PHAssetCollection?
                //PHAssetCollectionType: 相册类型：album,用户自定义相册；smartAlbum,系统相册；moment 事件排序相册
                //PHAssetCollectionSubtype:相册子类型：更详细的分类, 缩小查找范围，提高效率
                //PHFetchOptions?
                let collectionResults = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
                collectionResults.enumerateObjects({ (assetCollection, index, stop) in
                    if albumName == assetCollection.localizedTitle{
                        phAssetCollection = assetCollection
                        stop.initialize(to: true)
                    }
                })
                if let phAssetCollection = phAssetCollection {//有已经建好的相册，那么直接保存即可
                
                    //将已保存到胶卷相册的图片插入到新相册中，并置于首位
                    PHPhotoLibrary.shared().performChanges({
                        //根据已有相册创建一个操作相册的对象
                        collectionChangeRequest = PHAssetCollectionChangeRequest(for: phAssetCollection)
                        //给相册插入图片
                        collectionChangeRequest.insertAssets(phassetResults, at: IndexSet.init(integer: 0))
                        
                        
                    }, completionHandler: { (isS, error) in
                        if isS {
                            completion(true,"保存到自定义相册成功")
                        }else{
                            print("保存到新相册失败 error = " + (error?.localizedDescription)!)
                            completion(false,"保存到自定义相册失败")
                        }
                    })
                }else{//没有找到指定相册，需要新建相册
                    //创建相册
                    
                    var collectionPlaceHolder : String!
                    var collectionChangeRequest: PHAssetCollectionChangeRequest!
                    PHPhotoLibrary.shared().performChanges({
                        //创建一个相册
                        collectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                        //保存其占位符
                        collectionPlaceHolder = collectionChangeRequest.placeholderForCreatedAssetCollection.localIdentifier
                    }, completionHandler: { (isCollectionCreateSuccess, error) in
                        if isCollectionCreateSuccess {
                            //根据占位符来获取相册
                            let phAssetCollection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [collectionPlaceHolder], options: nil)
                            //print(phassetCollection.firstObject)
                            
                            //将已保存到胶卷相册的图片插入到新相册中，并置于首位
                            PHPhotoLibrary.shared().performChanges({
                                //创建一个操作相册的对象
                                collectionChangeRequest = PHAssetCollectionChangeRequest(for: phAssetCollection.firstObject!)
                                //给相册插入图片
                                collectionChangeRequest.insertAssets(phassetResults, at: IndexSet.init(integer: 0))
                                
                                
                            }, completionHandler: { (isS, error) in
                                if isS {
                                    completion(true,"保存到自定义相册成功")
                                }else{
                                    print("保存到新相册失败 error = " + (error?.localizedDescription)!)
                                    completion(false,"保存到自定义相册失败")
                                }
                            })
                            
                        }else{
                            completion(false,"保存到自定义相册失败")
                            print("创建相册失败 error = " + (error?.localizedDescription)!)
                        }
                    })
                }
                
            }else{
                completion(false,"保存到自定义相册失败")
                print("保存到胶卷相册失败 error = \(String(describing: error?.localizedDescription))")
            }
        })
    }
}
//MARK:保存到文件中
extension UIImage {
    
    /// 保存数据到文件中
    ///
    /// - Parameters:
    ///   - data: 数据
    ///   - name: 数据名称
    static func insert(image:UIImage,name:String) ->Bool{
        guard let data = UIImageJPEGRepresentation(image, 1.0) else {
            return false
        }
        return FileManager.insert(data: data, toFile: name)
    }
    /// 修改文件中的数据
    ///
    /// - Parameters:
    ///   - data: 数据
    ///   - name: 数据名称
    static func update(image:UIImage,name:String) ->Bool {
        guard let data = UIImageJPEGRepresentation(image, 1.0) else {
            return false
        }
        return FileManager.update(inFile: data, name: name)
    }
    /// 获取文件中的数据
    ///
    /// - Parameters:
    ///   - data: 数据
    ///   - name: 数据名称
    static func select(name:String) -> Data? {
        let data = FileManager.select(fromFile: name) as? Data
        return data
    }
    /// 移除文件中数据
    ///
    /// - Parameter name: 数据名称
    static func delete(name:String) ->Bool{
        return FileManager.delete(fromFile: name)
    }
}
