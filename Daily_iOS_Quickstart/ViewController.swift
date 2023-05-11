//
//  ViewController.swift
//  Daily_iOS_Quickstart
//
//  Created by Aisultan Askarov on 18.03.2023.
//

import UIKit
import Daily

class ViewController: UIViewController {
    
    //Create call client
    let callClient: CallClient = .init()
    
    //Dictionary of video views
    var videoViews: [ParticipantId: VideoView] = [:]
    
    //Room's URL
    let roomURLString: String = "[YOUR_DAILY_ROOM_URL]"
    
    //BUTTONS
    @IBOutlet weak var cameraInputButton: UIButton!
    @IBOutlet weak var microphoneInputButton: UIButton!

    @IBOutlet weak var leaveRoomButton: UIButton!
    
    //PARTICIPANT VIEWS
    @IBOutlet weak var participantsStack: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set call clients delegate
        self.callClient.delegate = self
        
        self.updateControls()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.enterRoom()
        
    }
        
    //Update the UI according to the input's(e.g camera off/on)
    private func updateControls() {
        
        //Camera Button
        cameraInputButton.setImage(UIImage(systemName: callClient.inputs.camera.isEnabled ? "video.fill": "video.slash.fill"), for: .normal)
        //Mic Button
        microphoneInputButton.setImage(UIImage(systemName: callClient.inputs.microphone.isEnabled ? "mic.fill": "mic.slash.fill"), for: .normal)

    }

    
    private func enterRoom() {
        
        guard let roomURL = URL(string: roomURLString) else {
            return
        }
        // This call is where you'd add a meeting token to join a private room.
        callClient.join(url: roomURL, token: nil) { result in
            
            print(result)
            // You can either handle the join event in a callback or in a delegate method
            
        }
        
    }
    
    //Button Actions
    
    @IBAction func didTapToggleCamera(_ sender: Any) {
        //Dissable & Enable your camera
        let isEnabled = self.callClient.inputs.camera.isEnabled
        self.callClient.setInputEnabled(.camera, !isEnabled)
        
    }
    
    @IBAction func didTapToggleMicrophone(_ sender: Any) {
        //Dissable & Enable your microphone
        let isEnabled = self.callClient.inputs.microphone.isEnabled
        self.callClient.setInputEnabled(.microphone, !isEnabled)
        
    }
    
    @IBAction func didTapLeaveRoom(_ sender: Any) {
        self.callClient.leave()
    }
    
}

//Event listener delegate
extension ViewController: CallClientDelegate {

    //Handle a remote participant joining
    func callClient(_ callClient: CallClient, participantJoined participant: Participant) {
        print("Participant \(participant.id) joined the call")
        
        // Create a new view for the participant's video feed
        let participantVideoView = VideoView()
        
        // Determine whether the video input is from the camera or screen
        let cameraTrack = participant.media?.camera.track
        let screenTrack = participant.media?.screenVideo.track
        let videoTrack = screenTrack ?? cameraTrack
        
        // Set the track for the participant's video view
        participantVideoView.track = videoTrack
        
        // Add the new participant to the video views dictionary
        self.videoViews[participant.id] = participantVideoView
        
        // Add the participant's video view to the stack view
        let videoView = self.videoViews[participant.id]
        self.participantsStack.addArrangedSubview(videoView!)
        
        // Update the layout of the view
        self.view.setNeedsLayout()
    }
    
    // Handle a participant updating (e.g. their tracks changing)
    func callClient(_ callClient: CallClient, participantUpdated participant: Participant) {
        
        print("Participant \(participant.id) Updated")

        //Determine whether the video input is screen or camera
        let cameraTrack = participant.media?.camera.track
        let screenTrack = participant.media?.screenVideo.track
        let videoTrack = cameraTrack ?? screenTrack
        
        //Update the track for a participants video view
        self.videoViews[participant.id]?.track = videoTrack
        
        self.view.setNeedsLayout()

    }

    //Handle a participant leaving
    func callClient(_ callClient: CallClient, participantLeft participant: Participant, withReason reason: ParticipantLeftReason) {
        
        print("Participant \(participant.id) Left The Room")
        
        //Remove participant's value from the dictionary and video view from the stack
        if let videoView = self.videoViews.removeValue(forKey: participant.id) {
           self.participantsStack.removeArrangedSubview(videoView)
        }
        
    }
    
    func callClient(_ callClient: CallClient, inputsUpdated inputs: InputSettings) {
        
        print("Inputs Updated")
        
        //Handle UI updates
        self.updateControls()
    }
    
}

