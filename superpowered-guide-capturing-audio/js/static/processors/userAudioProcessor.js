import { SuperpoweredWebAudio } from "../superpowered/SuperpoweredWebAudio.js";

class UserAudioProcessor extends SuperpoweredWebAudio.AudioWorkletProcessor {

  // Runs after the constructor
  onReady() {
    this.inputGain = 0.5;
    this.previousInputGain = 0;

    // Notify the main scope that we're prepared.
    this.sendMessageToMainScope({ event: "ready" });
  }

  // onDestruct is called when the parent AudioWorkletNode.destruct() method is called.
  // You should clear up all Superpowered objects and allocated buffers here.
  onDestruct() {
      // Nothing to clear in this example.
  }

  onMessageFromMainScope(message) {
    if (message.type === "parameterChange") {
      if (message.payload?.id === "inputGain") this.inputGain = message.payload.value;
    }
  }

  processAudio(inputBuffer, outputBuffer, buffersize, parameters) {
    // Apply volume while copy the input buffer to the output buffer.
    // Gain is smoothed, starting from "previousInputGain" to "inputGain".
    this.Superpowered.Volume(
      inputBuffer.pointer,
      outputBuffer.pointer,
      this.previousInputGain,
      this.inputGain,
      buffersize
    );
    this.previousInputGain = this.inputGain; // Save the gain for the next round.
  }
}

// The following code registers the processor script in the browser, please note the label and reference.
if (typeof AudioWorkletProcessor !== "undefined") registerProcessor("UserAudioProcessor", UserAudioProcessor);
export default UserAudioProcessor;
