//
//  RequestDataModels.swift
//  HTTPNetworkService
//
//  Created by Manu Singh on 09/02/21.
//

import Foundation


public struct GetRequestData : GetRequestDataConvertible {
    public var url: String
    public var queryStrings: [String : String]
    public var headers: [String : String]
    public init(url:String,queryStrings:[String:String],headers:[String:String]){
        self.url = url
        self.queryStrings = queryStrings
        self.headers = headers
    }
}

public struct PostRequestData : PostRequestDataConvertible {
    public var url: String
    public var parameters: [String : Any]
    public var headers: [String : String]
    public init(url:String,parameters:[String:Any],headers:[String:String]){
        self.url = url
        self.parameters = parameters
        self.headers = headers
    }
}

public struct MultipartRequestData: MultipartDataConvertible {
    public var url: String
    public var parameters: [String : Any]
    public var headers: [String : String]
    public var files: [[String : Any]]
    
    public init(url:String,parameters:[String:Any],headers:[String:String],files:[[String:Any]]){
        self.url = url
        self.parameters = parameters
        self.headers = headers
        self.files  = files
    }
    
}
