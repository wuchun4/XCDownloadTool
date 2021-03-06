//
//  XCDownloadTool.swift
//  XCDownloadToolExample
//
//  Created by Simon on 2017/2/24.
//  Copyright © 2017年 Simon. All rights reserved.
//

import Foundation


open class XCDownloadTool:NSObject , URLSessionDataDelegate{
    
    /// Download the file path
    open private(set) var targetPath:String?
    
    /// The download file storage location
    open var targetDirectory:String?
    
    /// Whether to overwrite the existing file， default false
    open var shouldOverwrite:Bool = false
    
    /// Whether from the temporary file recovery， default false
    open var shouldResume:Bool = false
    
    /// File identifier
    open var fileIdentifier:String?
    
    /// The downloaded file size
    open private(set) var currentFileSize:UInt64 = 0
    
    /// The total length of file
    open private(set) var fileTotalSize:UInt64 = 0
    
    /// Whether the file download is complete
    open private(set) var isFinished:Bool = false
    
    /// Download progress block
    open var downloadProgress:((Float) -> Void)?
    
    /// Download finished block
    open var downLoadCompletion:((Bool ,String?, Error?) -> Void)?
    
    /// Whether to delete temporary folder file when the download is complete
    open var removeTempFile:Bool = true
    
    fileprivate static let Key_FileTotalSize:String = "Key_FileTotalSize"
    fileprivate static let kAFNetworkingIncompleteDownloadFolderName:String = "XCIncomplete"
    fileprivate var session:URLSession?
    fileprivate var task:URLSessionDataTask?
    fileprivate var outputStream:OutputStream?
    
    
    
    public convenience init(url:URL , targetDirectory:String?, shouldResume:Bool) {
        self.init(url: url, fileIdentifier: nil, targetDirectory: targetDirectory, shouldResume: shouldResume)
    }
    
    public convenience init(url:URL, shouldResume:Bool) {
        self.init(url: url, fileIdentifier: nil, targetDirectory: nil, shouldResume: shouldResume)
    }
    
    public convenience init(url:URL, fileIdentifier:String?, targetDirectory:String?, shouldResume:Bool) {
        self.init()
        
        self.shouldResume = shouldResume;
        self.fileIdentifier = fileIdentifier;
        if fileIdentifier == nil{
            let md5str = XCDownloadTool.hashStr(string: url.description)
            self.fileIdentifier = md5str
        }
        let tempPath:String = self.tempPath()
        var targetPath1:String? = targetDirectory;
        let fileManager = FileManager.default
        if targetPath1 == nil{
            targetPath1 = tempPath
        }
        var isdirectory:ObjCBool = false
        
        let havePath:Bool = fileManager.fileExists(atPath: targetPath1!, isDirectory: &isdirectory)
        if !havePath {
            do{
                try fileManager.createDirectory(atPath: targetPath1!, withIntermediateDirectories: true, attributes: nil)
            }catch _ as NSError{
                
            }
        }
        
        if isdirectory.boolValue{
            let fileName = self.fileIdentifier;
            self.targetPath = NSString.path(withComponents: [targetPath1!,fileName!])
        }else{
            self.targetPath = targetPath1;
        }
        
        if !self.shouldResume{
            let fileDescriptor = open(tempPath, O_CREAT | O_EXCL | O_RDWR, 0666)
            if fileDescriptor > 0{
                close(fileDescriptor)
            }
        }
        self.isFinished = false
        self.getFileSize()
        self.creatDownloadSessionTask(url: url)
        
    }
    
    fileprivate static func hashStr(string:String?)-> String?{
        
        let hex:Int? = string?.hashValue
        if let _ = hex{
            let hashStr = String(hex!)
            return hashStr
        }
        var str:String? = string?.replacingOccurrences(of: "http", with: "")
        str = string?.replacingOccurrences(of: "/", with: "")
        return str
    }
    
    fileprivate static var tempFolder:String?
    open static func cacheFolder() -> String?{
        
        let fileMana = FileManager.default
        
        if tempFolder == nil{
            let cacheDir:String = NSTemporaryDirectory()
            tempFolder = cacheDir.appending(kAFNetworkingIncompleteDownloadFolderName)
        }
        
        do{
            try fileMana.createDirectory(atPath: tempFolder!, withIntermediateDirectories: true, attributes: nil)
        }catch _ as NSError{
            tempFolder = nil
        }
        return tempFolder
    }
    
    open func tempPath() -> String {
        var tempPath:String? = nil;
        if self.fileIdentifier != nil{
            tempPath = XCDownloadTool.cacheFolder()?.appending("/" +  self.fileIdentifier!)
        }else if self.targetPath != nil{
            let md5Str = XCDownloadTool.hashStr(string: self.targetPath)
            tempPath = XCDownloadTool.cacheFolder()?.appending("/" +  md5Str!)
        }
        return tempPath!
    }
    
    fileprivate func getFileSize() -> Void {
        
        if !self.shouldResume{
            return
        }
        let fileManager:FileManager = FileManager.default
        let filePath:String = self.tempPath()
        var attributes:[FileAttributeKey : Any]?
        do {
            attributes = try fileManager.attributesOfItem(atPath: filePath)
        } catch _ as NSError {
            
        }
        let fileCurrentSize:UInt64? = attributes?[FileAttributeKey.size] as? UInt64
        if fileCurrentSize != nil {
            
            let fileTotalSize:UInt64? = XCDownloadTool.stringValue(path: filePath, key: XCDownloadTool.Key_FileTotalSize)
            self.currentFileSize = fileCurrentSize!
            if let _ = fileTotalSize {
                self.fileTotalSize = fileTotalSize!
                DispatchQueue.main.async { //[weak self] () -> Void in
                    if let _ = self.downloadProgress {
                        let value1:Double = Double(self.currentFileSize)
                        let value2:Double = Double(self.fileTotalSize)
                        let prograss:Float = Float(value1.divided(by:value2))
                        self.downloadProgress?( prograss )
                    }
                }
            }
        }
    }
    
    fileprivate func creatDownloadSessionTask(url:URL) -> Void {
        if self.currentFileSize == self.fileTotalSize && self.currentFileSize != 0{
            self.downFinish(error: nil)
            return;
        }
        let session:URLSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue())
        var request:URLRequest = URLRequest(url: url) //Mutable
        let rangeStr = "bytes=\(self.currentFileSize)-"
        request.setValue(rangeStr, forHTTPHeaderField: "Range")
        let task:URLSessionDataTask = session.dataTask(with: request )
        self.session = session;
        self.task = task;
    }
    
    public func startDownload() -> Void {
        if !self.shouldOverwrite{
            let fileManager = FileManager.default
            var isdirectory:ObjCBool = false
            let haveFile:Bool = fileManager.fileExists(atPath: self.targetPath! , isDirectory: &isdirectory )
            if haveFile == true && isdirectory.boolValue == false{
                
                let fileTotalSize:UInt64? = XCDownloadTool.stringValue(path: self.targetPath!, key: XCDownloadTool.Key_FileTotalSize)
                var attributes:[FileAttributeKey : Any]?
                do {
                    attributes = try fileManager.attributesOfItem(atPath: self.targetPath!)
                } catch _ as NSError {
                    
                }
                let fileCurrentSize:UInt64? = attributes?[FileAttributeKey.size] as? UInt64
                if (fileTotalSize != nil) && fileTotalSize == fileCurrentSize{
                    DispatchQueue.main.async {
                        self.isFinished = true;
                        self.downLoadCompletion?( true, self.targetPath, nil)
                        return;
                    }
                }
            }
        }
        
        if self.task?.state == URLSessionTask.State.suspended {
            self.task?.resume()
        }
    }
    
    public func suspendDownload() -> Void {
        if self.task?.state == URLSessionTask.State.running {
            self.task?.suspend()
        }
    }
    
    //--------------------------
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void){
        
        self.isFinished = false
        let filePath = self.tempPath()
        let outputStream:OutputStream? = OutputStream(toFileAtPath: filePath, append: self.shouldResume)
        outputStream?.open()
        self.outputStream = outputStream
        if self.currentFileSize == 0{
            let totalSize:UInt64 = UInt64(response.expectedContentLength)
            let totalSizeString:String = "(\(totalSize))"
            _ = XCDownloadTool.extendedStringValue(path: filePath, key: XCDownloadTool.Key_FileTotalSize, value: totalSizeString)
            self.fileTotalSize = totalSize
        }
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data){
        
        _ = data.withUnsafeBytes { self.outputStream?.write($0, maxLength: data.count) }
        self.currentFileSize += UInt64(data.count)
        DispatchQueue.main.async {
            self.downloadProgress?(Float(Double(self.currentFileSize).divided(by: Double(self.fileTotalSize))) )
        }
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?){
        self.outputStream?.close()
        self.outputStream = nil
        self.session?.invalidateAndCancel()
        self.downFinish(error: error)
    }
    
    //--------------------------------
    fileprivate func downFinish(error:Error?) -> Void {
        var localError:Error? = error;
        if error == nil{
            let tempPath = self.tempPath()
            let downloadedBytes = XCDownloadTool.fileSize(atPath: tempPath)
            if downloadedBytes < 2{
                let fileManager:FileManager = FileManager.default
                if fileManager.fileExists(atPath: tempPath) {
                    do {
                        try fileManager.removeItem(atPath: tempPath)
                    } catch let error as NSError {
                        localError = error
                    }
                }else{
                    localError = NSError(domain: "文件为空", code: 3000, userInfo: nil)
                }
            }else if let _ = self.targetPath{
                let fileManager:FileManager = FileManager.default
                if self.shouldOverwrite{
                    if fileManager.fileExists(atPath: self.targetPath!){
                        do {
                            try fileManager.removeItem(atPath: self.targetPath!)
                        } catch let error as NSError {
                            localError = error
                        }
                    }
                }
                do {
                    try fileManager.moveItem(atPath: tempPath, toPath: self.targetPath!)
                } catch let error as NSError {
                    localError = error
                }
            }
        }
        
        DispatchQueue.main.async {
            self.isFinished = (localError == nil)
            self.downLoadCompletion?( self.isFinished , self.targetPath, localError)
        }
    }
    
    open static func fileSize(atPath:String) -> UInt64 {
        var fileSize:UInt64 = 0;
        let fileMana:FileManager = FileManager.default
        if fileMana.fileExists(atPath: atPath){
            do{
                let fileDict:[FileAttributeKey : Any]? = try fileMana.attributesOfItem(atPath: atPath)
                if let _ = fileDict{
                    fileSize = fileDict?[FileAttributeKey.size] as! UInt64
                }
            }catch _ as NSError{
                
                
            }
        }
        return fileSize
    }
    
    deinit{
        self.outputStream?.close()
        self.outputStream = nil
        self.session?.invalidateAndCancel()
    }
    
    fileprivate static func extendedStringValue(path:String, key:String, value:String) -> Bool{
        
        let data:Data? = value.data(using: String.Encoding.utf8)
        
        let result = data?.withUnsafeBytes {
            setxattr(path, key, $0, (data?.count)!, 0, 0)
        }
        
        if result == 0{
            return true
        }else{
            return false
        }
    }
    
    fileprivate static func stringValue(path:String, key:String) -> UInt64?{
        var bufLength:Int = listxattr(path, nil, 0, 0)
        repeat{
            
            bufLength = getxattr(path, key, nil, 0, 0, 0)
            if bufLength < 0{
                return nil
            }else {
                var data:Data = Data(count: bufLength)
                _ =  data.withUnsafeMutableBytes {
                    getxattr(path, key, $0, data.count, 0, 0)
                }
                
                var result:String? = String(data: data, encoding: String.Encoding.utf8)
                result = result?.replacingOccurrences(of: "(", with: "")
                result = result?.replacingOccurrences(of: ")", with: "")
                if let _ = result {
                    let value:UInt64 = UInt64(result!)!
                    return value
                }
                return 0
            }
        }while (true)
    }
}




