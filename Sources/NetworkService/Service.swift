import Foundation


fileprivate func generateBoundary()->String{
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    var boundary = "-------"
    boundary += String((0..<35).map{ _ in letters.randomElement()! })
    boundary += "--------"
    return boundary
}

public class NetworkTask {
    
    static var degaultSession:URLSession = URLSession.init(configuration: URLSessionConfiguration.default, delegate: SessionDelegate(), delegateQueue: nil)
        
    var urlRequest:URLRequest
    
    var task:URLSessionDataTask?
    
    init(urlRequest:URLRequest) {
        self.urlRequest = urlRequest
    }
    
    deinit {
        task?.cancel()
    }
    
    public func completion(_ completionHandler:@escaping(Result<NetworkTaskSuccessResult, NetworkTaskFailureResult>)->Void)->Self{
        task = NetworkTask.degaultSession.dataTask(with: urlRequest, completionHandler: {[weak self]
            data, response, error in
            guard let strongSelf = self else { return }
            completionHandler(strongSelf.transform(data: data, response: response, error: error))
        })
        task?.resume()
        return self
    }
    
    func transform(data:Data?,response:URLResponse?,error:Error?)->Result<NetworkTaskSuccessResult, NetworkTaskFailureResult> {
        guard error == nil else {
            return Result.failure(NetworkTaskFailureResult(urlRequest: urlRequest, error: error!))
        }
        return Result.success(NetworkTaskSuccessResult.init(data: data, response: response, urlRequest: urlRequest))
    }
    
}

class SessionDelegate:NSObject,URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void){
        completionHandler(.useCredential,URLCredential.init(trust: challenge.protectionSpace.serverTrust!))
    }
}

public func request(requestData : GetRequestDataConvertible)->NetworkTask? {
    guard let urlRequest = URLRequest.init(getRequestData: requestData) else { return nil }
    return NetworkTask.init(urlRequest: urlRequest)
}

public func request(requestData : PostRequestDataConvertible)->NetworkTask? {
    guard let urlRequest = URLRequest.init(postRequestData: requestData) else { return nil }
    return NetworkTask.init(urlRequest: urlRequest)
}

public func request(requestData : MultipartDataConvertible)->NetworkTask? {
    guard let urlRequest = URLRequest.init(multiPartRequestData: requestData) else { return nil }
    return NetworkTask.init(urlRequest: urlRequest)
}

public struct NetworkTaskSuccessResult {
    public var data:Data?
    public var response:URLResponse?
    public var urlRequest:URLRequest
}

public struct NetworkTaskFailureResult:Error,CustomStringConvertible,CustomDebugStringConvertible,LocalizedError {
    public var debugDescription: String {
        return description
    }
    
    public var description: String {
        return error.localizedDescription
    }
    
    var localizedDescription : String {
        return error.localizedDescription
    }
    
    public var urlRequest:URLRequest
    var error:Error
}

extension URLRequest {
    init?(getRequestData : GetRequestDataConvertible) {
        var fullUrl = "\(getRequestData.url)"
        fullUrl.setUrlParameters(getRequestData.queryStrings)
        guard let properUrl = URL(string: fullUrl) else {
            return nil
        }
        self.init(url: properUrl)
        httpMethod  =  "GET"
        setRequestHeaders(headers: getRequestData.headers)
    }
    
    init?(postRequestData : PostRequestDataConvertible){
        guard let url = URL(string: postRequestData.url) else {
            return nil
        }
        self.init(url: url)
        httpMethod  =  "POST"
        setPostRequestBody(parameters: postRequestData.parameters)
        setRequestHeaders(headers: postRequestData.headers)
    }
    
    init?(multiPartRequestData : MultipartDataConvertible) {
        self.init(postRequestData: multiPartRequestData)
        let boundary = generateBoundary()
        setMultipartRequestBody(requestData: multiPartRequestData, boundary: boundary)
        setMultipartRequestHeaders(headers: multiPartRequestData.headers, boundary: boundary)
    }
    
}

extension NetworkTaskSuccessResult {
    public func serializedObject()->Any?{
        return data?.getSerializedObject()
    }
    
    public func getSerializedString()->String? {
        guard let data = self.data else { return nil }
        let dataString = String(data: data, encoding: String.Encoding.utf8)
        return dataString
    }
}
