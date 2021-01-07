//
//  Location.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 10/2/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import Foundation
import MessageKit
import CoreLocation

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}
