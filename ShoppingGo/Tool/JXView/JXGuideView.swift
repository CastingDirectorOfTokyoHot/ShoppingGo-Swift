//
//  JJXGuideView.swift
//  ShoppingGo
//
//  Created by 杜进新 on 2017/7/12.
//  Copyright © 2017年 杜进新. All rights reserved.
//

import UIKit

private let reuseIdentifier = "CellId"

enum GuidePageStyle {
    case number
    case point
}

class JXGuideView: UIView,UICollectionViewDelegate,UICollectionViewDataSource {
    
    ///图片数组
    var images = Array<String>()
    ///当前页码
    var currentPage = 0
    var style : GuidePageStyle = .point
    typealias DismissBlock =  ((_ guide:JXGuideView)->())?
    var dismissBlock : DismissBlock
    
    /// 首次安装和升级安装要显示引导页
    static var isShowGuideView: Bool {
        let version = Bundle.main.version
        
        if  ///非首次安装且不是升级那么不显示
            let oldVersion = UserDefaults.standard.string(forKey: "version"),
            oldVersion == version {
            
            return false
        }else{
            UserDefaults.standard.set(version, forKey: "version")
            UserDefaults.standard.synchronize()
            
            return true
        }
    }
    
    
    lazy var collectionView : UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = self.bounds.size
        //layout.itemSize = CGSize(width: 200, height: 300)
        layout.scrollDirection = .horizontal
        
        let collection = UICollectionView(frame: self.bounds, collectionViewLayout: layout)
        collection.backgroundColor = UIColor.clear
        collection.dataSource = self
        collection.delegate = self
        //self.collectionView?.collectionViewLayout = layout
        
        collection.isPagingEnabled = true
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.register(GuideImageView.self, forCellWithReuseIdentifier: reuseIdentifier)
        return collection
    }()
    
    lazy var pageLabel: UILabel = {
        let lab = UILabel()
        lab.frame = CGRect(origin: CGPoint(), size: CGSize(width: 100, height: 30))
        lab.textColor = UIColor.white
        lab.textAlignment = .center
        return lab
    }()
    lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.pageIndicatorTintColor = UIColor.darkGray
        pc.currentPageIndicatorTintColor = UIColor.white
        pc.currentPage = 0
        pc.frame = CGRect(origin: CGPoint(), size: CGSize(width: 100, height: 20))
        return pc
    }()
    lazy var enterButton: UIButton = {
        let button = UIButton()
        button.setTitle("进入", for: .normal)
        button.frame = CGRect(origin: CGPoint(), size: CGSize(width: 80, height: 40))
        //button.sizeToFit()
        button.setTitleColor(UIColor.white, for: .normal)
        button.addTarget(self, action: #selector(touchDismiss(button:)), for: .touchUpInside)
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.isHidden = true
        return button
    }()
    
    
    init(frame: CGRect, block:DismissBlock) {
        super.init(frame: frame)
        
        self.dismissBlock = block
        
        backgroundColor = UIColor.clear
        
        
        addSubview(self.collectionView)
        addSubview(self.enterButton)
        
        for i in 1...4 {
            self.images.append(String(format: "guide_%d", i))
        }
        enterButton.center = CGPoint(x: center.x, y: bounds.height - 50)
        if style == .point {
            addSubview(self.pageControl)
            pageControl.center = CGPoint(x: center.x, y: enterButton.center.y + 25 + 10)
            pageControl.numberOfPages = self.images.count
            
        }else{
            addSubview(self.pageLabel)
            pageLabel.center = CGPoint(x: self.center.x, y: enterButton.center.y + 25 + 10)
        }

        self.collectionView.reloadData()
        resetPage(page: currentPage)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! GuideImageView
        
        // Configure the cell
        cell.contentView.backgroundColor = UIColor.randomColor
        cell.imageView.backgroundColor = UIColor.randomColor
    
        
        let urlStr = images[indexPath.item]
        if
            let url = URL.init(string: urlStr),
            urlStr.hasPrefix("http"){
            cell.imageView.setImageWith(url, placeholderImage: nil)
        }else{
            if let path = Bundle.main.path(forResource: urlStr, ofType: nil) {//这种方式不能获取到images.xcassets中的图片
                cell.imageView.image = UIImage(contentsOfFile: path)
            }else{
                cell.imageView.image = UIImage(named: urlStr)
            }
            
        }
//
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("点击：\(indexPath.item)")
    }
    
}
//MARK: - imageView gesture method
extension JXGuideView {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x / self.bounds.width
        currentPage = Int(offset)
        resetPage(page: currentPage)
    }
    
    func resetPage(page:Int) {
        if page == self.images.count - 1 {
            self.enterButton.isHidden = false
        }else{
            self.enterButton.isHidden = true
        }
        if style == .point {
            pageControl.currentPage = currentPage
        }else{
            pageLabel.text = "\(self.currentPage + 1)/\(self.images.count)"
        }
    }
    
    func touchDismiss(button:UIButton) {
        //收起
        print("收起")
        if let block = dismissBlock {
            block(self)
        }
    }
}

/// cell 图片视图，用于缩放和处理其他特殊事件
class GuideImageView: UICollectionViewCell{

    lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.isUserInteractionEnabled = true
        //iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView.frame = self.contentView.bounds
        self.contentView.addSubview(self.imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
