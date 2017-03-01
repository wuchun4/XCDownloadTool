//
//  XCDownloadTool.swift
//  XCDownloadToolExample
//
//  Created by Simon on 2017/2/24.
//  Copyright © 2017年 Simon. All rights reserved.
//

import Foundation


class XCDownloadTool:NSObject , URLSessionDataDelegate{
    
    public private(set) var targetPath:String?
    public var targetDirectory:String?
    public var shouldOverwrite:Bool = false
    public var shouldResume:Bool = false
    public var fileIdentifier:String?
    public private(set) var currentFileSize:UInt64 = 0
    public private(set) var fileTotalSize:UInt64 = 0
    public private(set) var isFinished:Bool = false
    public var downloadProgress:((Float) -> Void)?
    public var downLoadCompletion:((Bool ,String?, Error?) -> Void)?
    public var removeTempFile:Bool = true
    
    private static let Key_FileTotalSize:String = "Key_FileTotalSize"
    private static let kAFNetworkingIncompleteDownloadFolderName:String = "XCIncomplete"
    private var session:URLSession?
    private var task:URLSessionDataTask?
    private var outputStream:OutputStream?
    
    
    
    convenience init(url:URL , targetDirectory:String?, shouldResume:Bool) {
        self.init(url: url, fileIdentifier: nil, targetDirectory: targetDirectory, shouldResume: shouldResume)
    }
    
    convenience init(url:URL, shouldResume:Bool) {
        self.init(url: url, fileIdentifier: nil, targetDirectory: nil, shouldResume: shouldResume)
    }
    
    init(url:URL, fileIdentifier:String?, targetDirectory:String?, shouldResume:Bool) {
        super.init()
        
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
            let fileName = url.lastPathComponent;
            self.targetPath = NSString.path(withComponents: [targetPath1!,fileName])
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
        
        
        if !self.shouldOverwrite{
            if fileManager.fileExists(atPath: self.targetPath!){
                DispatchQueue.main.async {
                    self.isFinished = true;
                    self.downLoadCompletion?( true, self.targetPath, nil)
                }
            }
        }
    }
    
    static func hashStr(string:String?)-> String?{
        
        //        guard let messageData = string?.data(using:String.Encoding.utf8) else { return nil }
        //        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        //
        //        _ = digestData.withUnsafeMutableBytes {digestBytes in
        //            messageData.withUnsafeBytes {messageBytes in
        //                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
        //            }
        //        }
        //
        //        let md5Hex =  digestData.map { String(format: "%02hhx", $0) }.joined()
        let hex:Int? = string?.hashValue
        if let _ = hex{
            let hashStr = String(hex!)
            return hashStr
        }
        var str:String? = string?.replacingOccurrences(of: "http", with: "")
        str = string?.replacingOccurrences(of: "/", with: "")
        return str
    }
    
    private static var tempFolder:String?
    public static func cacheFolder() -> String?{
        
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
    
    public func tempPath() -> String {
        var tempPath:String? = nil;
        if self.fileIdentifier != nil{
            tempPath = XCDownloadTool.cacheFolder()?.appending("/" +  self.fileIdentifier!)
        }else if self.targetPath != nil{
            let md5Str = XCDownloadTool.hashStr(string: self.targetPath)
            tempPath = XCDownloadTool.cacheFolder()?.appending("/" +  md5Str!)
        }
        return tempPath!
    }
    
    private func getFileSize() -> Void {
        
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
    
    private func creatDownloadSessionTask(url:URL) -> Void {
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
    internal func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void){
        
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
    
    internal func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data){
        
        _ = data.withUnsafeBytes { self.outputStream?.write($0, maxLength: data.count) }
        self.currentFileSize += UInt64(data.count)
        DispatchQueue.main.async {
            self.downloadProgress?(Float(Double(self.currentFileSize).divided(by: Double(self.fileTotalSize))) )
        }
    }
    
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?){
        self.outputStream?.close()
        self.outputStream = nil
        self.session?.invalidateAndCancel()
        self.downFinish(error: error)
    }
    
    //--------------------------------
    private func downFinish(error:Error?) -> Void {
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
    
    public static func fileSize(atPath:String) -> UInt64 {
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
    
    private static func extendedStringValue(path:String, key:String, value:String) -> Bool{
        
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
    
    private static func stringValue(path:String, key:String) -> UInt64?{
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




