//
//  MyIoT.swift
//  IoT-Kit
//
//  Created by Daniel Egerev on 6/14/17.
//  Copyright © 2017 Daniel Egerev. All rights reserved.
//

import Foundation
import IoTTicketSwiftAPI

class MyIoT {
    
    static let baseURL = "https://my.iot-ticket.com/api/v1"
    var client: IoTTicketClient! = nil
    var deviceDetails: Device! = nil
    
    init() {
        
    }
    
    init(client: IoTTicketClient, deviceDetails: Device) {
        self.client = client
        self.deviceDetails = deviceDetails
    }
}
