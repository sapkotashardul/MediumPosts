//
//  HomeViewController.swift
//  weatherBot
//
//  Created by Enrico Piovesan on 2017-12-28.
//  Copyright © 2017 Enrico Piovesan. All rights reserved.
//

import UIKit
import Toolbar
import SnapKit
import PromiseKit
import AVFoundation
import MessageUI

class HomeViewController: UIViewController, UIViewControllerTransitioningDelegate, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var iconWeatherImageView: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var iconButtonImageView: UIImageView!
    @IBOutlet weak var temperatureView: UIView!
    
    var empaticaVC = EmpaticaViewController()
    var backButton: UIButton = UIButton()
    
    var messages = [Message]()
    
    var empaticaStatus: Bool = false
    
    let transition = CircularTransition()
    
    override func loadView() {
        super.loadView()
        
        //Gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor.purpleEnd.cgColor, UIColor.purpleStart.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
        
        //load weather
        loadLocalWeather()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //button
        menuButton.layer.cornerRadius = menuButton.frame.size.width / 2
        menuButton.layer.borderColor = UIColor.buttonBorder.cgColor
        menuButton.layer.borderWidth = 1
        menuButton.layer.shadowColor = UIColor.black.cgColor
        menuButton.layer.shadowOpacity = 0.2
        menuButton.layer.shadowOffset = CGSize.zero
        menuButton.layer.shadowRadius = 3
        wrapperView.layer.cornerRadius = wrapperView.frame.size.width / 2
    
        
        //hide elements
        cityNameLabel.alpha = 0
//        dateLabel.alpha = 0
        iconWeatherImageView.alpha = 0
        
        self.backButton = UIButton()
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(export))
        
        self.dateLabel.addGestureRecognizer(gestureRecognizer)
        self.dateLabel.isUserInteractionEnabled = true

        
    }
    
    @objc func export(){
        
        let emailAlertController = UIAlertController(
            title: "Export files to your email",
            message: "Please enter your email below",
            preferredStyle: UIAlertController.Style.alert)
        
        let sendEmail = UIAlertAction(title: "Send",
                                      style: .default) {
                                        [unowned self] action in
                                        
                                        guard let textField = emailAlertController.textFields?.first
                                            else {return}
                                        
                                        
                                        let email = textField.text as! String
                                        
                                        print("Sending email to", email)
                                        
                                        do{//Check to see the device can send email.
                                            if(try MFMailComposeViewController.canSendMail()) {
                                                print("Can send email.")
                                                
                                                let mail = MFMailComposeViewController()
                                                mail.mailComposeDelegate = self
                                                
                                                //Set the subject and message of the email
                                                    mail.setSubject("Message Log")
                                                    mail.setMessageBody("Attached", isHTML: false)
                                            
                                                mail.setToRecipients([email])
                                                
                                                for fileName in  ["messages", "acc", "gsr", "ibi"] {
                                                    // hr and IBI not working
                                                    let fileManager = FileManager.default
                                                    let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create: true)
                                                    let fileURL = documentDirectory.appendingPathComponent(fileName).appendingPathExtension("txt")
                                                    print("File Path: \(fileURL.path)")
                                                    let fileData = NSData(contentsOfFile: fileURL.path)
                                                    print("File data loaded.")
                                                    // TO DO {do catch} inside attachment
                                                mail.addAttachmentData(fileData! as Data, mimeType: "text/txt", fileName: fileName + ".txt")
                                                }
                                                self.present(mail, animated: true, completion: nil)
                                            }
                                        } catch {
                                            
                                        }
        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        emailAlertController.addTextField()
        emailAlertController.textFields?.first?.text = "sapkota@mit.edu"
        emailAlertController.addAction(sendEmail)
        emailAlertController.addAction(cancelAction)
        
        self.present(emailAlertController, animated: true, completion: nil)

        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let secondVC = segue.destination as! ChatViewController

        empaticaVC.initEmpatica(backButton: self.backButton)
        secondVC.backButton = self.backButton

        secondVC.transitioningDelegate = self
        secondVC.messages = self.messages
        secondVC.modalPresentationStyle = .custom
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        transition.transitionMode = .present
        transition.startingPoint = wrapperView.center
        transition.circleColor = UIColor.chatBackgroundEnd
        
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .dismiss
        transition.startingPoint = wrapperView.center
        transition.circleColor = menuButton.backgroundColor!
        
        return transition
    }
    
    func loadLocalWeather() {
        firstly {
            getLocation()
        }.then { (coordinates) -> Promise<Weather> in
            WeatherService(WeatherRequest(coordinates: coordinates)).getWeather()
        }.then { weather in
            self.updateWeatherData(weather)
        }.catch{ (error) in
            print("error! ")
        }
    }
    
    func updateWeatherData(_ weather: Weather) {
        DispatchQueue.main.async {
            
            self.cityNameLabel.text = weather.location?.city ?? "Unknow City"
            let dateFormatterHeader = DateFormatter()
            dateFormatterHeader.setLocalizedDateFormatFromTemplate("MMMM dd yyyy")
            self.dateLabel.text = dateFormatterHeader.string(from: Date())
            self.iconWeatherImageView.image = weather.condition.weatherIcon.image
            self.temperatureLabel.text = "Prospero"

//            self.temperatureLabel.text = Int(weather.condition.temp).description
            self.unitLabel.text = weather.unit!.temperature
            self.statusLabel.text = weather.condition.text.uppercased()
            
            UIView.animate(withDuration: 0.5) {
                self.cityNameLabel.alpha = 1
                self.dateLabel.alpha = 1
                self.iconWeatherImageView.alpha = 1
                self.temperatureView.alpha = 1
            }
            
        }
    }
    
    func getLocation() -> Promise<CLLocationCoordinate2D> {
        return Promise { fulfill, reject in
            firstly {
                CLLocationManager.promise()
                }.then { location in
                    fulfill(location.coordinate)
                }.catch { (error) in
                    reject(error)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

