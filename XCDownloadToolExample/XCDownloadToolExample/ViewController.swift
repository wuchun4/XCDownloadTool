//
//  ViewController.swift
//  XCDownloadToolExample
//
//  Created by Simon on 2017/2/24.
//  Copyright © 2017年 Simon. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var progressLabel:UILabel!
    @IBOutlet weak var imageView:UIImageView!
    
    var downloadTool:XCDownloadTool?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }

    func initData() -> Void {
        
        let url:URL = URL(string: "https://camo.githubusercontent.com/91481851b3130c22fdbb0d3dfb91869fa4bd2174/687474703a2f2f692e696d6775722e636f6d2f30684a384d7a572e676966")!
        let cacheDir:String = NSTemporaryDirectory()
        let folder = cacheDir.appending("simon")
        self.downloadTool = XCDownloadTool(url: url, fileIdentifier: nil, targetDirectory: folder, shouldResume: true)
        self.downloadTool?.shouldOverwrite = true
        self.downloadTool?.downloadProgress = {[weak self] (progress)-> Void in
            
            self?.progressLabel.text = "progress: \(progress)"
        }
        
        self.downloadTool?.downLoadCompletion = {[weak self] (finished:Bool ,targetPath:String?, error:Error?) -> Void in
            self?.progressLabel.text = "download finished"
            if let _ = targetPath{
                let image:UIImage? = UIImage.init(contentsOfFile: targetPath!)
                self?.imageView.image = image
            }
        }
    }

    
    @IBAction func clickStart(sender:UIButton) -> Void {
        switch sender.tag {
        case 10:
            self.downloadTool?.startDownload()
            break
            
        case 11:
            self.downloadTool?.suspendDownload()
            break
        default:
            break
        }
        
    }
}

