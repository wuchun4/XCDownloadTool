# XCDownloadTool for swift3

[![Software License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE.md)
[![Latest Stable Version](http://img.shields.io/cocoapods/v/XCDownloadTool.svg)](https://github.com/wuchun4/XCDownloadTool)
![Platform](http://img.shields.io/cocoapods/p/XCDownloadTool.svg)





#### [English](https://github.com/wuchun4/XCDownloadTool/blob/master/README_EN.md)

swift 断点续传下载工具，重启APP恢复临时下载数据

![image](https://github.com/wuchun4/XCDownloadTool/blob/master/2017-03-07%2010.46.53.gif)

## 安装
通过 CocoaPods

```ruby
pod 'XCDownloadTool'
```

##使用方法
```swift
        let url:URL = URL(string: "https://......./687474703a2f2f692e696d6775722e636f6d2f30684a384d7a572e676966")!
        let cacheDir:String = NSTemporaryDirectory()
        let directory = cacheDir.appending("simon")
        self.downloadTool = XCDownloadTool(url: url, fileIdentifier: nil, targetDirectory: directory, shouldResume: true)
        //是否覆盖旧文件
        self.downloadTool?.shouldOverwrite = true
        
        //下载进度        
        self.downloadTool?.downloadProgress = {[weak self] (progress)-> Void in
            
            self?.progressLabel.text = "progress: \(progress)"
        }
        
        //下载完成
        self.downloadTool?.downLoadCompletion = {[weak self] (finished:Bool ,targetPath:String?, error:Error?) -> Void in
            self?.progressLabel.text = "download finished"
            if let _ = targetPath{
                let image:UIImage? = UIImage.init(contentsOfFile: targetPath!)
                self?.imageView.image = image
            }
        }
```

```swift
//开始或继续下载
self.downloadTool?.startDownload()
```

```swift
//暂停下载
self.downloadTool?.suspendDownload()
```

## 代码许可

The MIT License (MIT). 详情见 [License 文件](https://github.com/wuchun4/XCDownloadTool/blob/master/LICENSE).
