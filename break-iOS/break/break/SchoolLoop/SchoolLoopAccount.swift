//
//  SchoolLoopAccount.swift
//  break
//
//  Created by Saagar Jha on 1/26/16.
//  Copyright © 2016 Saagar Jha. All rights reserved.
//

import Foundation

@objc(SchoolLoopAccount)
class SchoolLoopAccount: NSObject, NSCoding {
	var username: String
	var password: String
	var fullName: String
	var studentID: String
    var loggedIn: Bool = false

	init(username: String, password: String, fullName: String, studentID: String) {
		self.username = username
		self.password = password
		self.fullName = fullName
		self.studentID = studentID
		super.init()
	}

	required init?(coder aDecoder: NSCoder) {
		username = aDecoder.decodeObjectForKey("username") as? String ?? ""
		password = SchoolLoopKeychain.sharedInstance.getPasswordForUsername(username) ?? ""
		fullName = aDecoder.decodeObjectForKey("fullName") as? String ?? ""
		studentID = aDecoder.decodeObjectForKey("studentID") as? String ?? ""
		super.init()
	}

	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(username, forKey: "username")
		SchoolLoopKeychain.sharedInstance.setPassword(password, forUsername: username)
		aCoder.encodeObject(fullName, forKey: "fullName")
		aCoder.encodeObject(studentID, forKey: "studentID")
	}
}
