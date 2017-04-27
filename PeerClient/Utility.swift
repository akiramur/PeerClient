//
//  Utility.swift
//  PeerClient
//
//  Created by Akira Murao on 10/18/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation

class Utility {

    struct Supports {
        var sctp: Bool

        init() {
            self.sctp = false
        }
    }

    var supports: Supports

    init() {
        self.supports = Supports()
    }

    // MARK: Utility - make a random String with random length
    
    static func randString(maxLength: Int) -> String {
        let len = self.randBetween(min: maxLength, max:maxLength)
        var letter = [UInt8]( repeating: 0, count: len)
        //for (var i = 0; i < len; i++) {
        for i in (0 ..< len) {
            letter[i] = UInt8(self.randBetween(min: 65, max:90))
        }
        
        var generatedString: String = ""
        if  let letterString = NSString(bytes: letter, length: letter.count, encoding: String.Encoding.utf8.rawValue) {
            generatedString = letterString as String
        }
        
        return generatedString
    }
    
    static func randBetween(min: Int, max: Int) -> Int {
        let rand = Int(arc4random())
        return (rand % (max - min + 1)) + min
        //return (arc4random() % (max - min + 1)) + min
    }

    // MARK: Utility - make a random String with random length
/*
    func randString(maxLength: Int) -> String {
        let len = self.randBetween(min: maxLength, max:maxLength)
        var letter = [UInt8]( repeating: 0, count: len)
        for i in 0 ..< len {
            letter[i] = UInt8(self.randBetween(min: 65, max:90))
        }

        /*
         var generatedString: String = ""
         if  let letterString = NSString(bytes: letter, length: letter.count, encoding: NSUTF8StringEncoding) {
         generatedString = letterString as String
         }
         */
        let generatedString = String(bytes: letter, encoding: String.Encoding.utf8) ?? ""
        return generatedString
    }

    func randBetween(min: Int, max: Int) -> Int {
        let rand = Int(arc4random())
        return (rand % (max - min + 1)) + min
        //return (arc4random() % (max - min + 1)) + min
    }
 */
}
