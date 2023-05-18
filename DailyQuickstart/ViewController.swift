import UIKit
import Daily

final class ViewController: UIViewController {
    // The client used to manage the video call.
    private let callClient: CallClient = .init()

    // The local participant video view.
    private let localVideoView: VideoView = .init()

    // A dictionary of remote participant video views.
    private var videoViews: [ParticipantId: VideoView] = [:]

    // The URL for the room to join.
    private let roomURLString: String = "[YOUR_DAILY_ROOM_URL]"

    // MARK: - Buttons

    @IBOutlet private weak var cameraInputButton: UIButton!
    @IBOutlet private weak var microphoneInputButton: UIButton!
    @IBOutlet private weak var leaveRoomButton: UIButton!

    // MARK: -

    // A container stack view for participant video views.
    @IBOutlet private weak var participantsStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the call client's delegate.
        self.callClient.delegate = self

        // Add the local participant's video view to the stack view.
        self.participantsStack.addArrangedSubview(self.localVideoView)

        // Disable the idle timer, so the screen will remain active while the app is in use.
        UIApplication.shared.isIdleTimerDisabled = true

        // Handle UI updates.
        self.updateControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Automatically join the room specified by `roomURLString` when this view controller appears.
        self.enterRoom()
    }

    // Updates the UI according to the inputs (e.g camera off/on).
    private func updateControls() {
        // Set the image for the camera button.
        cameraInputButton.setImage(
            UIImage(systemName: callClient.inputs.camera.isEnabled ? "video.fill": "video.slash.fill"),
            for: .normal
        )

        // Set the image for the mic button.
        microphoneInputButton.setImage(
            UIImage(systemName: callClient.inputs.microphone.isEnabled ? "mic.fill": "mic.slash.fill"),
            for: .normal
        )
    }

    private func enterRoom() {
        guard let roomURL = URL(string: roomURLString) else {
            return
        }

        // This call is where you would add a meeting token to join a private room.
        callClient.join(url: roomURL, token: nil) { result in
            print(result)

            // You can either handle the join event in a callback or in a delegate method.
        }
    }

    // MARK: - Button Actions

    @IBAction func didTapToggleCamera(_ sender: Any) {
        // Disable or enable the camera.
        let isEnabled = self.callClient.inputs.camera.isEnabled
        self.callClient.setInputEnabled(.camera, !isEnabled)
    }

    @IBAction func didTapToggleMicrophone(_ sender: Any) {
        // Disable or Enable the microphone.
        let isEnabled = self.callClient.inputs.microphone.isEnabled
        self.callClient.setInputEnabled(.microphone, !isEnabled)
    }

    @IBAction func didTapLeaveRoom(_ sender: Any) {
        self.callClient.leave()
    }
}

// MARK: - CallClientDelegate

extension ViewController: CallClientDelegate {
    // Handles a remote participant joining.
    func callClient(_ callClient: CallClient, participantJoined participant: Participant) {
        print("Participant \(participant.id) joined the call.")

        // Create a new view for this participant's video track.
        let videoView = VideoView()
        
        // Determine whether the video input is from the camera or screen.
        let cameraTrack = participant.media?.camera.track
        let screenTrack = participant.media?.screenVideo.track
        let videoTrack = screenTrack ?? cameraTrack
        
        // Set the track for this participant's video view.
        videoView.track = videoTrack
        
        // Add this participant's video view to the dictionary.
        self.videoViews[participant.id] = videoView
        
        // Add this participant's video view to the stack view.
        self.participantsStack.addArrangedSubview(videoView)
    }

    // Handles a participant updating (e.g. their tracks changing).
    func callClient(_ callClient: CallClient, participantUpdated participant: Participant) {
        print("Participant \(participant.id) updated.")

        // Determine whether the video track is for a screen or camera.
        let cameraTrack = participant.media?.camera.track
        let screenTrack = participant.media?.screenVideo.track
        let videoTrack = cameraTrack ?? screenTrack

        if participant.info.isLocal {
            // Update the track for the local participant's video view.
            self.localVideoView.track = videoTrack
        } else {
            // Update the track for a remote participant's video view.
            self.videoViews[participant.id]?.track = videoTrack
        }
    }

    // Handles a participant leaving.
    func callClient(_ callClient: CallClient, participantLeft participant: Participant, withReason reason: ParticipantLeftReason) {
        print("Participant \(participant.id) left the room.")

        // Remove remote participant's video view from the dictionary and stack view.
        if let videoView = self.videoViews.removeValue(forKey: participant.id) {
           self.participantsStack.removeArrangedSubview(videoView)
        }
    }

    func callClient(_ callClient: CallClient, inputsUpdated inputs: InputSettings) {
        print("Inputs updated.")

        // Handle UI updates.
        self.updateControls()
    }
}
