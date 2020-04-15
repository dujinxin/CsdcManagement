//
//  FirstViewController.swift
//  CsdcManagement
//
//  Created by 飞亦 on 9/4/19.
//  Copyright © 2019 COB. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class FirstViewController: UIViewController {
    
    var backBlock : ((_ ip: String, _ port: Int16)->())?
    var ip: String?
    var int16: Int16 = 0
    
    var socket : GCDAsyncUdpSocket!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.white
        
        let queue = DispatchQueue.init(label: "queue")
        let s = GCDAsyncUdpSocket(delegate: self, delegateQueue: queue, socketQueue: nil)
        
        do {
            try s.bind(toPort: 60010)
        } catch let error {
            print("bind = ",error.localizedDescription)
        }
        do {
            try s.enableBroadcast(true)
        } catch let error {
            print("enableBroadcast = ",error.localizedDescription)
        }
        
        do {
            try s.beginReceiving()
        } catch let error {
            print("beginReceiving = ",error.localizedDescription)
        }
        self.socket = s
        
        self.broadcast()
    }
    //广播
    func broadcast() {
        let json = try? JSONSerialization.data(withJSONObject: ["cmd": "findMiner"], options: [])
        guard let data = json else { return }
        self.socket.send(data, toHost: "224.0.0.110", port: 60000, withTimeout: 10, tag: 0)
    }
    @IBAction func jump(_ sender: Any) {
        if let block = self.backBlock {
            block(ip!,int16)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension FirstViewController: GCDAsyncUdpSocketDelegate {
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print("没有连接 ",error?.localizedDescription)
    }
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("关闭")
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        let s = GCDAsyncUdpSocket.host(fromAddress: address)
        let d = GCDAsyncUdpSocket.port(fromAddress: address)
        print(s,d)
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        if tag == 0 {
            print("发送成功")
        }
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        if tag == 0 {
            print("发送失败 ",error?.localizedDescription)
        }
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        let s = GCDAsyncUdpSocket.host(fromAddress: address)
        let d = GCDAsyncUdpSocket.port(fromAddress: address)
        print(s,d)
        //let ss = String(data: data, encoding: .utf8)
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return
        }
        print(json)
        guard let dict = json as? Dictionary<String, Any>, let port = dict["port"] as? Int16 else {
            return
        }
        sock.close()
        
        self.ip = s
        self.int16 = port
    }
    
}
