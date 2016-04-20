//
//  LoginViewController.swift
//  BoilingTorch
//
//  Created by Timothy Richardson on 03/02/2016.
//  Copyright © 2016 Timothy Richardson. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    // @IBOutlet weak var loginButton: FBSDKLoginButton!
    @IBOutlet weak var loginButton: FBSDKLoginButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        let loginButton: FBSDKLoginButton = FBSDKLoginButton()
        loginButton.center = self.view.center
        self.view!.addSubview(loginButton)
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // If we have the uid stored, the user is already logger in - no need to sign in again!
        
        if NSUserDefaults.standardUserDefaults().valueForKey("uid") != nil && DataService.dataService.CURRENT_USER_REF.authData != nil {
            self.performSegueWithIdentifier("CurrentlyLoggedIn", sender: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if (error === nil) {
            
            
            let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
            DataService.dataService.BASE_REF.authWithOAuthProvider("facebook", token: accessToken, withCompletionBlock: { error, authData in
                if error != nil {
                    print("Login failed. \(error)")
                } else {
                    print("Logged in! \(authData)")
                
                    let newUser = [
                    "provider": authData.provider,
                    "email": authData.providerData["email"] as? NSString as? String,
                    "username": authData.providerData["displayName"] as? NSString as? String,
                    ]
                    
                    DataService.dataService.BASE_REF.childByAppendingPath("users").childByAppendingPath(authData.uid).setValue(newUser)
                    
                    
                    NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: "uid")
                        self.performSegueWithIdentifier("CurrentlyLoggedIn", sender: nil)
                }
            })
            
            
        } else {
            print(error.localizedDescription)
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User logged out...")
    }
    
    
    @IBAction func tryLogin(sender: AnyObject) {
        let email = emailField.text
        let password = passwordField.text
        
        if (self.isValidEmail(email!))
        
        {
            print("valid");
            if (password != "")
            {
                DataService.dataService.BASE_REF.authUser(email, password: password, withCompletionBlock: { error, authData in
                    
                    if (error != nil) {
                        // an error occurred while attempting login.
                        if let errorCode = FAuthenticationError(rawValue: error.code) {
                            switch (errorCode) {
                            case .UserDoesNotExist:
                                
                                self.loginErrorAlert("Oops!", message: "invalid user.")
                                
                            case .InvalidEmail:
                                self.loginErrorAlert("Oops!", message: "invalid email.")
                                
                            case .InvalidPassword:
                                self.loginErrorAlert("Oops!", message: "invalid password.")
                            
                            default:
                                self.loginErrorAlert("Oops!", message: "Something went wrong.")
                            }
                        }
                    } else {
                        
                        NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: "uid")
                        
                        // Enter the app!
                        self.performSegueWithIdentifier("CurrentlyLoggedIn", sender: nil)
                        
                        // User is logged in
                    }
                })
            }
            else
            {
                self.loginErrorAlert("Oops!", message: "Password can't be blank.")
            }
            
        }
        else
        {
            self.loginErrorAlert("Oops!", message: "This email is not valid.")
            
            print("This is invalid")
        }
        
        
        
        
    }
    
        func loginErrorAlert(title: String, message: String) {
        
        // Called upon login error to let the user know login didn't work.
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        let emailTest = NSPredicate(format: "SELF MATCHES%@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
}