//
//  ViewController.swift
//  Daily_iOS_Quickstart
//
//  Created by Aisultan Askarov on 18.03.2023.
//

import UIKit
import Daily

final class ViewController: UIViewController {
    // Create call client
    private let callClient: CallClient = .init()

    // The local participant's video view
    private let localVideoView: VideoView = .init()

    // Dictionary of video views
    private var videoViews: [ParticipantId: VideoView] = [:]

    // Room's URL
    private let roomURLString: String = "[YOUR_DAILY_ROOM_URL]"

    // MARK: - Buttons

    @IBOutlet private weak var cameraInputButton: UIButton!
    @IBOutlet private weak var microphoneInputButton: UIButton!
    @IBOutlet private weak var leaveRoomButton: UIButton!

    // MARK: -

    // Participant views
    @IBOutlet private weak var participantsStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the call client's delegate
        self.callClient.delegate = self

        // Add the local participant's video view to the stack view
        self.participantsStack.addArrangedSubview(self.localVideoView)

        self.updateControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.enterRoom()
    }

    // Update the UI according to the input's(e.g camera off/on)
    private func updateControls() {
        // Camera Button
        cameraInputButton.setImage(
            UIImage(systemName: callClient.inputs.camera.isEnabled ? "video.fill": "video.slash.fill"),
            for: .normal
        )

        // Mic Button
        microphoneInputButton.setImage(
            UIImage(systemName: callClient.inputs.microphone.isEnabled ? "mic.fill": "mic.slash.fill"),
            for: .normal
        )
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

    // MARK: - Button Actions

    @IBAction func didTapToggleCamera(_ sender: Any) {
        // Dissable & Enable your camera
        let isEnabled = self.callClient.inputs.camera.isEnabled
        self.callClient.setInputEnabled(.camera, !isEnabled)
    }

    @IBAction func didTapToggleMicrophone(_ sender: Any) {
        // Dissable & Enable your microphone
        let isEnabled = self.callClient.inputs.microphone.isEnabled
        self.callClient.setInputEnabled(.microphone, !isEnabled)
    }

    @IBAction func didTapLeaveRoom(_ sender: Any) {
        self.callClient.leave()
    }
}

// MARK: - CallClientDelegate

// Event listener delegate
extension ViewController: CallClientDelegate {
    // Handle a remote participant joining
    func callClient(_ callClient: CallClient, participantJoined participant: Participant) {
        print("Participant \(participant.id) joined the call")

        // Create a new view for the participant's video feed
        let videoView = VideoView()
        
        // Determine whether the video input is from the camera or screen
        let cameraTrack = participant.media?.camera.track
        let screenTrack = participant.media?.screenVideo.track
        let videoTrack = screenTrack ?? cameraTrack
        
        // Set the track for the participant's video view
        videoView.track = videoTrack
        
        // Add the new participant to the video views dictionary
        self.videoViews[participant.id] = videoView
        
        // Add the participant's video view to the stack view
        self.participantsStack.addArrangedSubview(videoView)
    }

    // Handle a participant updating (e.g. their tracks changing)
    func callClient(_ callClient: CallClient, participantUpdated participant: Participant) {
        print("Participant \(participant.id) Updated")

        // Determine whether the video input is screen or camera
        let cameraTrack = participant.media?.camera.track
        let screenTrack = participant.media?.screenVideo.track
        let videoTrack = cameraTrack ?? screenTrack

        if participant.info.isLocal {
            // Update the track for the local participant's video view
            self.localVideoView.track = videoTrack
        } else {
            // Update the track for a participants video view
            self.videoViews[participant.id]?.track = videoTrack
        }
    }

    // Handle a participant leaving
    func callClient(_ callClient: CallClient, participantLeft participant: Participant, withReason reason: ParticipantLeftReason) {
        print("Participant \(participant.id) Left The Room")

        // Remove participant's value from the dictionary and video view from the stack
        if let videoView = self.videoViews.removeValue(forKey: participant.id) {
           self.participantsStack.removeArrangedSubview(videoView)
        }
    }

    func callClient(_ callClient: CallClient, inputsUpdated inputs: InputSettings) {
        print("Inputs Updated")

        // Handle UI updates
        self.updateControls()
    }
}
