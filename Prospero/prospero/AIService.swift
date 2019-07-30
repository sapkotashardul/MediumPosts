//
//  AIService.swift
//  AiBasicApp
//
//  Created by Enrico Piovesan on 2018-01-04.
//  Copyright © 2018 Enrico Piovesan. All rights reserved.
//

import UIKit
import Alamofire
import PromiseKit
import ApiAI
import AVFoundation

class AIService {
    
//    let aiUrl = URLGenerator.aiApiUrlForPathString(path: "query?v=20150910")
    var aiRequest: AIRequest?
    var headers: HTTPHeaders?
    var chatVC : ChatViewController?
    var speechSynthesizer: AVSpeechSynthesizer?
    var speechUtterance: AVSpeechUtterance?
    var msg: Message?

//    var speechSynthesizer = AVSpeechSynthesizer()
//    var speechUtterance: AVSpeechUtterance = AVSpeechUtterance()

    init(){
        let configuration = AIDefaultConfiguration()
        let apiai = ApiAI.shared()
        configuration.clientAccessToken = "1fc3753d570742abb12a15419883cd34"// Prosero v1 use "8c253081ae5e4dfe88c2074b8ff51d4c" // for Prospero ITW use 1fc3753d570742abb12a15419883cd34
        apiai?.configuration = configuration
        speechSynthesizer = AVSpeechSynthesizer()
    }
    
//    init(_ aiRequest: AIRequest) {
//        self.aiRequest = aiRequest
//        self.headers = aiRequest.getHeaders()
//    }
    
    
    func triggerEvent(eventName: String)-> Promise<Message> {
       let requestEvent = ApiAI.shared()?.eventRequest()
        requestEvent?.event = AIEvent(name: eventName)
        
        return Promise { fulfill, reject in
            
            requestEvent?.setMappedCompletionBlockSuccess({ (requestEvent, response) in
                let response = response as! AIResponse
                if let textResponse = response.result.fulfillment.speech {
                    self.msg = Message(text: textResponse, date: Date(), type: .botText)
                    fulfill(self.msg!)
                }
            }, failure: { (requestEvent, error) in
                print(error!)
                self.msg = Message(text: "No message found", date: Date(), type: .botText)
                reject(error!)
            })
            
            ApiAI.shared().enqueue(requestEvent)
            
        }
        
    }
    
    func sendMessage(aiRequest: AIRequest)-> Promise<Message> {
        let request = ApiAI.shared().textRequest()
        
        request?.query = aiRequest.query
        
        return Promise { fulfill, reject in
        
        request?.setMappedCompletionBlockSuccess({ (request, response) in
            let response = response as! AIResponse
            if let textResponse = response.result.fulfillment.speech {
            self.msg = Message(text: textResponse, date: Date(), type: .botText)
                fulfill(self.msg!)
            }
        }, failure: { (request, error) in
            print(error!)
            self.msg = Message(text: "No message found", date: Date(), type: .botText)
            reject(error!)
        })
            
        ApiAI.shared().enqueue(request)
            
        }
        
    }
    
    
}
