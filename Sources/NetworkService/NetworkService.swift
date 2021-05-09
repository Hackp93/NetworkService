//
//  Network.swift
//  NearGroup
//
//  Created by Manu Singh on 14/06/19.
//  Copyright © 2019 Manu Singh. All rights reserved.
//

import Foundation

public class NetworkService {
    
    fileprivate func generateBoundary()->String{
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var boundary = "-------"
        boundary += String((0..<35).map{ _ in letters.randomElement()! })
        boundary += "--------"
        return boundary
    }
    public init(){}
}

public protocol HTTPNetworkProtocol {
    func sendGetRequest(requestData : GetRequestDataConvertible, completion : @escaping (NetworkResult)->Void)
    func sendPostRequest(requestData : PostRequestDataConvertible, completion : @escaping (NetworkResult)->Void)
    func sendMultipartRequest(requestData : MultipartDataConvertible, completion : @escaping (NetworkResult)->Void)
}

extension NetworkService : HTTPNetworkProtocol {
    
    public func sendGetRequest(requestData : GetRequestDataConvertible, completion : @escaping (NetworkResult)->Void){
        guard var urlRequest = getUrlGETRequest(requestData: requestData) else { return }
        urlRequest.setRequestHeaders(headers: requestData.headers)
        sendHttpUrlRequest(urlRequest: urlRequest) { (error, data,response) in
            self.handleServerResponse(response:Response.init(data: data, error: error, response: response), completion: completion)
        }
        
    }
    
    public func sendPostRequest(requestData : PostRequestDataConvertible, completion : @escaping (NetworkResult)->Void){
        var urlRequest = getUrlPostRequest(requestData: requestData)
        urlRequest.setPostRequestBody(parameters: requestData.parameters)
        urlRequest.setRequestHeaders(headers: requestData.headers)
        sendHttpUrlRequest(urlRequest: urlRequest) { (error, data, response) in
            self.handleServerResponse(response:Response.init(data: data, error: error, response: response), completion: completion)
        }
    }
    
    public func sendMultipartRequest(requestData : MultipartDataConvertible, completion : @escaping (NetworkResult)->Void){
        let boundary = generateBoundary()
        var urlRequest = getUrlPostRequest(requestData: requestData)
        urlRequest.setMultipartRequestBody(requestData: requestData, boundary: boundary)
        urlRequest.setMultipartRequestHeaders(headers: requestData.headers, boundary: boundary)
        sendHttpUrlRequest(urlRequest: urlRequest) { (error, data, response) in
            self.handleServerResponse(response:Response.init(data: data, error: error, response: response), completion: completion)
        }
    }
    
    fileprivate func getUrlPostRequest(requestData : PostRequestDataConvertible)->URLRequest{
        var urlRequest = URLRequest(url: URL(string: requestData.url)!)
        urlRequest.httpMethod  =  "POST"
        return urlRequest
    }
    
    fileprivate func getUrlGETRequest(requestData : GetRequestDataConvertible)->URLRequest?{
        var fullUrl = "\(requestData.url)"
        fullUrl.setUrlParameters(requestData.queryStrings)
        guard let properUrl = URL(string: fullUrl) else {
            return nil
        }
        var urlRequest = URLRequest(url: properUrl)
        urlRequest.httpMethod  =  "GET"
        return urlRequest
    }
    
    fileprivate func sendHttpUrlRequest(urlRequest : URLRequest,completion : @escaping (Error?, Data?,URLResponse?)->Void){
        let task =  URLSession.shared.dataTask(with: urlRequest, completionHandler: {
            data, response, error in
            completion(error,data, response)
        })
        task.resume()
    }
    
    fileprivate func handleServerResponse(response:Response ,completion :  @escaping (NetworkResult)->Void){
        guard response.error == nil else {
            completion((.failure(response.error!)))
            return
        }
        guard let data = response.data else {
            completion(.failure(NetworkError.init("unexpected response from server")))
            return
        }
        completion(.success(NetworkResultData.init(data: data,urlResponse: response.response)))
    }
}

public enum NetworkResult {
    case success(NetworkResultData)
    case failure(Error)
}

public struct NetworkResultData {
    public var data:Data
    public var urlResponse:URLResponse?
    
    public func serializedObject()->Any?{
        return data.getSerializedObject()
    }
    
    public func getSerializedString()->String? {
        let dataString = String(data: data, encoding: String.Encoding.utf8)
        return dataString
    }
    
}

fileprivate struct Response {
    var data:Data?
    var error:Error?
    var response:URLResponse?
}
