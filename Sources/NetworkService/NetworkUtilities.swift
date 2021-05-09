//
//  NetworkUtilities.swift
//  TalkLeague
//
//  Created by Manu Singh on 12/09/20.
//  Copyright © 2020 neargroup. All rights reserved.
//

import Foundation

public protocol GetRequestDataConvertible {
    var url:String { get }
    var queryStrings : [String:String] { get }
    var headers : [String:String] { get }
}

public protocol PostRequestDataConvertible {
    var url:String { get }
    var parameters : [String:Any] { get }
    var headers : [String:String] { get }
}

public protocol MultipartDataConvertible:PostRequestDataConvertible {
    var files : [[String:Any]] { get }
}

extension URLRequest {
    
    mutating func setPostRequestBody(parameters : [String:Any]){
        do {
            self.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to nsdata object and set it as request body
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    mutating func setMultipartRequestBody(requestData : MultipartDataConvertible,boundary : String){
        httpBody  =  createBodyWithParameters(parameters: requestData.parameters, files: requestData.files, boundary: boundary) as Data
    }
    
    mutating func setRequestHeaders(headers : [String:String]){
        self.addValue("application/json", forHTTPHeaderField: "Content-Type")
        setHeaders(headers: headers)
    }
    
    mutating func setMultipartRequestHeaders(headers : [String:String],boundary : String){
        setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        setValue("\(httpBody!.count)", forHTTPHeaderField:"Content-Length")
        setHeaders(headers: headers)
    }
    
    mutating func setHeaders(headers : [String:String]){
        self.addValue("application/json", forHTTPHeaderField: "Accept")
        for header in headers {
            self.addValue(header.value, forHTTPHeaderField: header.key)
        }
//        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
//        self.addValue(appVersion, forHTTPHeaderField: "Version-Code")
    }
    
}

extension Data {
    
    func getSerializedObject()->Any?{
        let jsonDict  = try? JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions.allowFragments)
        return jsonDict
    }
}

extension URLRequest {
    fileprivate func appendFiles(files:[[String:Any]],body : NSMutableData){
        
        for fileData in files {
            body.append("Content-Disposition:form-data; name=\"\(fileData["imagekey"] ?? "")\"; filename=\"\(fileData["filename"] ?? "")\"\r\n".data(using: String.Encoding.utf8)!)
            body.append("Content-Type: \(fileData["mime"] ?? "")\r\n\r\n".data(using: String.Encoding.utf8)!)
            body.append(fileData["content"] as! Data)
            body.append("\r\n".data(using: String.Encoding.utf8)!)
        }
    }
    
    fileprivate func createBodyWithParameters(parameters: [String: Any],files:[[String:Any]], boundary: String) -> NSData {
        let body = NSMutableData()
        
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
            body.append("\(value)\r\n".data(using: String.Encoding.utf8)!)
        }
        
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        appendFiles(files: files, body: body)
        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        return body
    }
}

extension String {
    
    mutating func setUrlParameters(_ parameters : [String:Any]){
        guard !parameters.isEmpty else { return }
        
        if self.contains("?") {
            self += "&"
        } else {
            self += "?"
        }
        for (key,value) in parameters {
            self.append("\(key)=\(value)&")
        }
        self = String(self.dropLast(1))
    }
    
}

