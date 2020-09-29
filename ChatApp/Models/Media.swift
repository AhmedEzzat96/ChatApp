//
//  Media.swift
//  ChatApp
//
//  Created by Ahmed Ezzat on 9/29/20.
//  Copyright © 2020 IDEAcademy. All rights reserved.
//

import Foundation
import MessageKit

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}
