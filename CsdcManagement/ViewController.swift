//
//  ViewController.swift
//  CsdcManagement
//
//  Created by 飞亦 on 8/31/19.
//  Copyright © 2019 COB. All rights reserved.
//

import UIKit
import SocketIO


class ViewController: UIViewController {

    var socket: SocketIO.SocketIOClient?
    var manager: SocketManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
    }
    @IBAction func jump(_ sender: Any) {
        
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "first") as? FirstViewController
        vc?.backBlock = { (ip, int16) in
        
//            let ip = "192.168.1.41"
//            let int16 = 8080
            //let manager = SocketManager(socketURL: URL(string: "http://localhost:8080")!, config: [.log(true), .compress])
            self.manager = SocketManager(socketURL: URL(string: "https://\(ip):\(int16)")!, config: [.log(true), .compress,.selfSigned(true),.sessionDelegate(self)])
            self.socket = self.manager?.defaultSocket
            
            self.socket?.on(clientEvent: .connect) {data, ack in
                print("======= socket connected")

            }
        
            self.socket?.on("currentAmount") {data, ack in
                guard let cur = data[0] as? Double else { return }
                
                self.socket?.emitWithAck("canUpdate", cur).timingOut(after: 0) {data in
                    self.socket?.emit("update", ["amount": cur + 2.50])
                }
                
                ack.with("Got your currentAmount", "dude")
            }
            self.socket?.on("message", callback: { (data, ack) in
                //print(data)
            })
            self.socket?.on(clientEvent: .error, callback: { (data, ack) in
                print("======= error",data)
            })
            self.socket?.on(clientEvent: .reconnect, callback: { (data, ack) in
                print("======= reconnect",data)
            })
            self.socket?.on(clientEvent: .reconnectAttempt, callback: { (data, ack) in
                print("======= reconnect",data)
            })
            self.socket?.on(clientEvent: .disconnect, callback: { (data, ack) in
                print("======= disconnect",data)
            })
            self.socket?.on(clientEvent: .websocketUpgrade, callback: { (data, ack) in
                print("======= websocketUpgrade",data)
            })
        
            self.socket?.connect()
        }
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    //socket io
    @IBAction func sendMessage() {
        self.socket?.emit("message", with: [["message": "123"]], completion: {
            print("123")
        })
    }
    
    
}
extension ViewController: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        //print("challenge = ",challenge.protectionSpace)
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential,credential)
        }
    }
}

