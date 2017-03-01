# XCDownloadTool for swift

[![Software License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE.md)
[![Latest Stable Version](http://img.shields.io/cocoapods/v/XCDownloadTool.svg)](https://github.com/wuchun4/XCDownloadTool)
![Platform](http://img.shields.io/cocoapods/p/XCDownloadTool.svg)




##### [中文说明](https://github.com/wuchun4/XCDownloadTool/blob/master/LICENSE)

#### Swift breakpoint continuingly download tools, restart the APP temporarily download data recovery

## Install
[CocoaPods](http://cocoapods.org)

```ruby
pod 'XCDownloadTool'
```

##Here's an example:
```swift
        let url:URL = URL(string: "https://camo.githubusercontent.com/91481851b3130c22fdbb0d3dfb91869fa4bd2174/687474703a2f2f692e696d6775722e636f6d2f30684a384d7a572e676966")!
        let cacheDir:String = NSTemporaryDirectory()
        let directory = cacheDir.appending("simon")
        self.downloadTool = XCDownloadTool(url: url, fileIdentifier: nil, targetDirectory: directory, shouldResume: true)
        //Overwrite the old file
        self.downloadTool?.shouldOverwrite = true
        
        //Download progress block        
        self.downloadTool?.downloadProgress = {[weak self] (progress)-> Void in
            
            self?.progressLabel.text = "progress: \(progress)"
        }
        
        //Download finished block
        self.downloadTool?.downLoadCompletion = {[weak self] (finished:Bool ,targetPath:String?, error:Error?) -> Void in
            self?.progressLabel.text = "download finished"
            if let _ = targetPath{
                let image:UIImage? = UIImage.init(contentsOfFile: targetPath!)
                self?.imageView.image = image
            }
        }
```

```swift
//To start or continue to download
self.downloadTool?.startDownload()
```

```swift
//Pause
self.downloadTool?.suspendDownload()
```

## License

The MIT License (MIT). See [License 文件](https://github.com/wuchun4/XCDownloadTool/blob/master/LICENSE).