//
//  ChatViewController.swift
//  weatherBot
//
//  Created by Enrico Piovesan on 2017-05-25.
//  Copyright © 2017 Enrico Piovesan. All rights reserved.
//

import UIKit
import Toolbar
import SnapKit
import ReverseExtension
import Alamofire
import PromiseKit
import AVFoundation
import InstantSearchVoiceOverlay

class ChatViewController: UIViewController, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate{
    
    //tool bar
    let containerView = UIView()
    let toolbar: Toolbar = Toolbar()
    var textView: UITextView?
    var item0: ToolbarItem?
    var item1: ToolbarItem?
    var item2: ToolbarItem?
    var tempImage: UIImage?
    var toolbarBottomConstraint: NSLayoutConstraint?
    var constraint: NSLayoutConstraint?
    let aiService: AIService = AIService()
    let voiceOverlayController = VoiceOverlayController()
    
//    var backButton: UIButton = UIButton()

    var backButton: UIButton?
    
    var recordingFinished:Bool = false
    var tappedRecordingButton:Bool = false
    
    //Messages
    var tableView = UITableView()
    var messages: [Message]?

    var empaticaVC = EmpaticaViewController()
    private var devices: [EmpaticaDeviceManager] = []
    
    //speech syntehsizer
    var speechSynthesizer = AVSpeechSynthesizer()
    var speechUtterance: AVSpeechUtterance = AVSpeechUtterance()
    var speechPaused: Bool = false
    var userFinishedSpeaking: Bool = false
    
    var stringToWrite: String?
    
    
//    var backButton.background : String = "Accelerometer" {
//        didSet {
//            detailLabel.text = sensor
//        }
//    }
    
    var isMenuHidden: Bool = false {
        didSet {
            if oldValue == isMenuHidden {
                return
            }
            self.toolbar.layoutIfNeeded()
            UIView.animate(withDuration: 0.3) {
                self.toolbar.layoutIfNeeded()
            }
        }
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.addSubview(containerView)
        containerView.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.view.snp.bottomMargin)
            make.right.equalTo(self.view)
            make.left.equalTo(self.view)
            make.top.equalTo(self.view.snp.topMargin)
        }
        //setup background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.chatBackgroundEnd.cgColor, UIColor.chatBackgroundStart.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = self.view.bounds
        containerView.layer.addSublayer(gradientLayer)
        
        //add tool bar
        containerView.addSubview(toolbar)
        self.toolbarBottomConstraint = self.toolbar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0)
        self.toolbarBottomConstraint?.isActive = true
        let bottomView = UIView()
        bottomView.backgroundColor = .chatBackgroundEnd
        containerView.addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(containerView)
            make.left.equalTo(containerView)
            make.top.equalTo(toolbar.snp.bottom)
            make.height.equalTo(100)
        }
        
        //add table view
        containerView.addSubview(tableView)
        tableView.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(toolbar.snp.top)
            make.right.equalTo(containerView)
            make.left.equalTo(containerView)
            make.top.equalTo(containerView)
        }
        
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.recordingFinished = voiceOverlayController.inputViewController?.recordingFinished ?? false
        
//        if (!self.homeViewMessages.isEmpty){
//        self.messages = self.homeViewMessages
//            print("HERHERHERHER")
//            print(self.messages)
//        }
        
        //add back button
//        self.backButton = UIButton()
//        if let backButton = backButton{
//            print("COLOROR", backButton.backgroundColor)
//        }else{
//          self.backButton = UIButton()
//            print("HERHERHERHERHERH")
//            if empaticaVC.empaticaStatus{
//                backButton!.backgroundColor = UIColor.green.withAlphaComponent(0.7)
//            } else{
//                backButton!.backgroundColor = UIColor.black.withAlphaComponent(0.7)
//
//            }
//        }
        
//        var backButton.backgroundColor: UIColor = {
//            didSet{
//                backButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
//            }
//        }
        
        if let backButton = backButton{
            self.backButton?.backgroundColor = backButton.backgroundColor
        } else {
            self.backButton = UIButton()
        }

        backButton!.clipsToBounds = true
        backButton!.layer.cornerRadius = 25
        backButton!.setImage(UIImage(named: "icon_close"), for: .normal)
        backButton!.addTarget(self, action: #selector(backHome), for: .touchUpInside)
        containerView.addSubview(backButton!)
        backButton!.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(containerView.snp.top).offset(15)
            make.height.equalTo(50)
            make.width.equalTo(50)
            make.centerX.equalTo(containerView)
        }
        
        empaticaVC.initEmpatica(backButton: backButton!)
        
        
//        backButton.clipsToBounds = true
//        backButton.layer.cornerRadius = 25
//        backButton.setImage(UIImage(named: "icon_close"), for: .normal)
//        backButton.addTarget(self, action: #selector(backHome), for: .touchUpInside)
//        containerView.addSubview(backButton)
//        backButton.snp.makeConstraints { (make) -> Void in
//            make.top.equalTo(containerView.snp.top).offset(15)
//            make.height.equalTo(50)
//            make.width.equalTo(50)
//            make.centerX.equalTo(containerView)
//        }
//
//        empaticaVC.initEmpatica(backButton: backButton)
        
        //setup tool bar
        let textView: UITextView = UITextView(frame: .zero)
        textView.delegate = self
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.backgroundColor = UIColor.black.withAlphaComponent(0.30)
        textView.textColor = .white
        self.textView = textView
        textView.layer.cornerRadius = 10
        print("textView.frame.height")
        item0 = ToolbarItem(customView: textView)
        containerView.addSubview(item0!)
        item0?.snp.makeConstraints {(make) -> Void in
            make.height.equalTo(40)
            make.width.equalTo(280)
//            make.left.equalTo(containerView.snp.left).offset(40)
        }
        
        tempImage = self.resizeImage(image: UIImage(named: "microphone")!, targetSize: CGSize(width: 25, height: 50))
        
        item1 = ToolbarItem(image: tempImage!, target: self, action: #selector(microphone))
        
        containerView.addSubview(item1!)
        item1!.tintColor = .mainGreen
        item1?.snp.makeConstraints{(make) -> Void in
//            make.bottom.equalTo(containerView.snp.bottom).offset(-8)
            make.left.equalTo(containerView.snp.left).offset(-9)
            make.right.equalTo(item0!.snp.left).offset(10)
        }
        item1!.setEnabled(true, animated: false)
        

        item2 = ToolbarItem(title: "SEND", target: self, action: #selector(send))
        containerView.addSubview(item2!)
        item2?.snp.makeConstraints{(make) -> Void in
            make.right.equalTo(containerView.snp.right).offset(-5)
        }
        item2!.tintColor = .mainGreen
        item2!.setEnabled(true, animated: false)
        
        
        toolbar.setItems([item1!, item0!, item2!], animated: false)
        toolbar.backgroundColor = .black
        
        let toolbarWrapperView = UIView()
        toolbarWrapperView.backgroundColor = .grayBlue
        toolbar.insertSubview(toolbarWrapperView, at: 1)
        toolbarWrapperView.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(toolbar)
            make.right.equalTo(toolbar)
            make.left.equalTo(toolbar)
            make.top.equalTo(toolbar)
        }
        
        
        let gestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hide))
        
        gestureRecognizer.addTarget(self, action: #selector(self.stopVoiceSynthesizer(_:)))

//        gestureRecognizer.addTarget(textView, action: #selector(textViewTouched(_:)))
//
        self.view.addGestureRecognizer(gestureRecognizer)
        
        //setup messages table view
        tableView.dataSource = self
        tableView.delegate = self
        tableView.re.delegate = self
        
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "UserTableViewCell", bundle: nil), forCellReuseIdentifier: "UserTableViewCell")
        tableView.register(UINib(nibName: "TextResponseTableViewCell", bundle: nil), forCellReuseIdentifier: "TextResponseTableViewCell")
        tableView.register(UINib(nibName: "ForecastResponseTableViewCell", bundle: nil), forCellReuseIdentifier: "ForecastResponseTableViewCell")
        tableView.estimatedRowHeight = 56
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = .clear
        
        
        tableView.re.scrollViewDidReachTop = { scrollView in
            print("scrollViewDidReachTop")
        }
        tableView.re.scrollViewDidReachBottom = { scrollView in
            print("scrollViewDidReachBottom")
        }

        self.tableView.reloadData()
        
        
        voiceOverlayController.settings.autoStop = true
        voiceOverlayController.settings.autoStopTimeout = 2
    voiceOverlayController.settings.layout.permissionScreen.title = "Welcome to Prospero!"
    
    voiceOverlayController.settings.layout.inputScreen.subtitleInitial = "Say something"
    voiceOverlayController.settings.layout.inputScreen.subtitleBullet = ""
    voiceOverlayController.settings.layout.inputScreen.subtitleBulletList = []

    voiceOverlayController.settings.layout.inputScreen.titleInProgress = ""
        
        sendWelcomeMessage()
        
    }
    
    @objc func stopVoiceSynthesizer(_ sender: UITapGestureRecognizer) {
        if speechSynthesizer.isSpeaking {
            // when synth is already speaking or is in paused state
            
            if speechSynthesizer.isPaused {
                speechSynthesizer.continueSpeaking()
            }else {
                speechSynthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
            }
    }
    }
    
//    @objc func textViewTouched(_ sender: UITapGestureRecognizer) {
//        self.tappedRecordingButton = false
//    }

    @objc func microphone(){

        self.tappedRecordingButton = true
        self.voiceOverlayController.start(on: self, textHandler: { (text, final, extraInfo) in
            print("voice output: \(String(describing: text))")
            self.textView!.text = text
        }, errorHandler: { (error) in
            print("voice output: error \(String(describing: error))")
        })
        

        DispatchQueue.global(qos: .userInitiated).async{
        while(!self.recordingFinished){
            self.recordingFinished = (self.voiceOverlayController.inputViewController?.recordingFinished ?? false)
        }
        
        DispatchQueue.main.async {
            self.send()
            self.recordingFinished = false
        }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        self.toolbar.setNeedsUpdateConstraints()
    }
    
    // MARK: back button
    @objc func backHome() {
        
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let destinationVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
        
//        do {
        guard let destinationVC = self.presentingViewController as? HomeViewController
            else {
                let destinationVC = HomeViewController()
                destinationVC.messages = self.messages!
                self.dismiss(animated: true, completion: nil)
                return
//                destinationVC.messages = self.messages!
            }
        destinationVC.messages = self.messages!
//    }
//            destinationVC.messages = self.messages!
//         catch{
//            var homeVC = HomeViewController()
//            homeVC.messages = self.messages!
//        }
 
//        print("DESTINATION VC ", destinationVC.messages)
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK:- tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let messages = self.messages
            else {
                var messages = [Message]()
                return messages.count
        }
        
        return messages.count
//
//        do { return messages!.count
//        } catch{
//            messages = [Message]()
//            return messages!.count
//        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages![messages!.count - (indexPath.row + 1)]
        
        switch message.type {
        case .user:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell", for: indexPath) as! UserTableViewCell
            cell.configure(with: message)
            return cell
        case .botText:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextResponseTableViewCell", for: indexPath) as! TextResponseTableViewCell
            cell.configure(with: message)
            return cell
        case .botForecast:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ForecastResponseTableViewCell", for: indexPath) as! ForecastResponseTableViewCell
            cell.configure(with: message)
            return cell
        }
            
    }
    
    // Mark - Tool bar
    
    @objc func hide() {
        self.textView?.resignFirstResponder()
    }
    
    @objc final func keyboardWillShow(notification: Notification) {
        moveToolbar(up: true, notification: notification)
    }
    
    @objc final func keyboardWillHide(notification: Notification) {
        moveToolbar(up: false, notification: notification)
    }
    
    @objc func send() {
        if self.textView!.text != "" {
            
            //configure AI Request
            let aiRequest = AIRequest(query: textView!.text, lang: "en")

            //Promise block
            firstly{
                self.aiService.sendMessage(aiRequest: aiRequest)
            }.then { (message) -> Void in
                self.sendMessage(self.aiService.msg!)
                
                let utterance = AVSpeechUtterance(string: message.text)
                
                utterance.voice = AVSpeechSynthesisVoice(language: "en-gb")
                self.speechSynthesizer.speak(utterance)
            
               // reduce everything to 1/16 th of the entire text count 
                let textCountLength = message.text.count / 16
                
                let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(textCountLength), repeats: false) { (timer) in
                    // do stuff 42 seconds later
                    if self.tappedRecordingButton {                     self.microphone()
                    }
                }

                }.catch{ (error) in
                //oh noes error
            }


            //user message
            let message = Message(text: self.textView!.text!, date: Date(), type: .user)
            self.sendMessage(message)
            
            //reset
            self.textView?.text = nil
            if let constraint: NSLayoutConstraint = self.constraint {
                self.textView?.removeConstraint(constraint)
            }
            self.toolbar.setNeedsLayout()
        }
        
    }
    
    
    func createTimeStamp() -> String{
        let now = Date()
        
        let formatter = DateFormatter()
        
        formatter.timeZone = TimeZone.current
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString = formatter.string(from: now)
        return dateString
    }
    
    
    func saveToFile(fileName: String, stringToWrite: String){
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create: true)
            let fileURL = documentDirectory.appendingPathComponent(fileName).appendingPathExtension("txt")
            print("File Path: \(fileURL.path)")
            print("WRITING TO FILE")
//            let stringToWrite = stringToWrite.joined(separator: "\n")
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                print("FILE NAME ALREADY EXISTS")
                var err:NSError?
                do{
                 let fileHandle = try FileHandle(forWritingTo: fileURL)
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(Data(stringToWrite.utf8))
                    fileHandle.closeFile()
//                else {
                
//                }
                } catch{
                    print("Can't open fileHandle \(err)")
//                    try stringToWrite.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
                }
            } else {
                try stringToWrite.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
            }
            
//            try stringToWrite.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
            
        } catch {
            print(error)
        }
        
    }
    
    // MARK:- send message
    func sendMessage(_ message: Message) {
        messages!.append(message)
        
        self.stringToWrite = self.createTimeStamp()
        
        
        switch message.type {
        case .user:
            self.stringToWrite = self.stringToWrite! + ", user"
        case .botText:
            self.stringToWrite = self.stringToWrite! + ", bot"
        case .botForecast:
            self.stringToWrite = self.stringToWrite! + ", botForecast"
        }
        
        self.stringToWrite = self.stringToWrite! + ", " + message.text + " \n"
        
        self.saveToFile(fileName: "messages", stringToWrite: self.stringToWrite!)
        
//        self.homeViewMessages = messages
        tableView.beginUpdates()
        tableView.re.insertRows(at: [IndexPath(row: messages!.count - 1, section: 0)], with: .automatic)
        tableView.endUpdates()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.isMenuHidden = true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let size: CGSize = textView.sizeThatFits(textView.bounds.size)
        if let constraint: NSLayoutConstraint = self.constraint {
            textView.removeConstraint(constraint)
        }
        self.constraint = textView.heightAnchor.constraint(equalToConstant: size.height)
        self.constraint?.priority = UILayoutPriority.defaultHigh
        self.constraint?.isActive = true
        self.tappedRecordingButton = false
    }

    final func moveToolbar(up: Bool, notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        let animationDuration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let keyboardHeight = up ? -(userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height : 0
        
        // Animation
        self.toolbarBottomConstraint?.constant = keyboardHeight
        UIView.animate(withDuration: animationDuration, animations: {
            self.toolbar.layoutIfNeeded()
        }, completion: nil)
        self.isMenuHidden = up
    }
    
    // MARK:- welcome message
    
    func sendWelcomeMessage() {
        let firstTime = true
        if firstTime {
//            let text = "Welcome to Prospero!"
            
            
            //Promise block
            firstly{
                self.aiService.triggerEvent(eventName: "Welcome")
                }.then { (message) -> Void in
                    self.sendMessage(self.aiService.msg!)
                    
                    let utterance = AVSpeechUtterance(string: message.text)
                    
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-gb")
                    self.speechSynthesizer.speak(utterance)
                    
                    // reduce everything to 1/16 th of the entire text count
                    let textCountLength = message.text.count / 16
                    
                    let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(textCountLength), repeats: false) { (timer) in
                        // do stuff 42 seconds later
                        if self.tappedRecordingButton {                     self.microphone()
                        }
                    }
                    
                }.catch{ (error) in
                    //oh noes error
            }

            
            
//            let utterance = AVSpeechUtterance(string: text)
//
//            utterance.voice = AVSpeechSynthesisVoice(language: "en-gb")
//
////            self.speechSynthesizer.speak(utterance)
//
//            let message = Message(text: text, date: Date(), type: .botText)
//            messages!.append(message)
        }
    }
}

