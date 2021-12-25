// Import the SuperpoweredWebAudio helper to allow us to extend the SuperpoweredWebAudio.AudioWorkletProcessor class
import { SuperpoweredWebAudio } from "../superpowered/SuperpoweredWebAudio.js";

class UserAudioProcessor extends SuperpoweredWebAudio.AudioWorkletProcessor {
  // Runs after the constructor
  onReady() {
    this.inputGain = 0.5;
    this.previousInputGain = 0.5;
    // Pass an event object over to the main scope to tell it everything is ready
    this.sendMessageToMainScope({ event: "ready" });
  }

  // onDestruct is called when the parent AudioWorkletNode.destruct() method is called.
  // You should clear up all SP class instances here.
  onDestruct() {}

  onMessageFromMainScope(message) {
    if (message.type === "parameterChange") {
      if (message.payload?.id === "inputGain")
        this.inputGain = message.payload.value;
    }
  }

  processAudio(inputBuffer, outputBuffer, buffersize, parameters) {
    // Here we apply the volume change to the singal
    this.Superpowered.Volume(
      inputBuffer.pointer,
      outputBuffer.pointer,
      this.previousInputGain,
      this.inputGain,
      buffersize
    );
    this.previousInputGain = this.inputGain;
  }
}

// The following code registers the processor script in the browser, notice the label and reference
if (typeof AudioWorkletProcessor !== "undefined")
  registerProcessor("UserAudioProcessor", UserAudioProcessor);
export default UserAudioProcessor;
