// Import the SuperpoweredWebAudio helper to allow us to extend the SuperpoweredWebAudio.AudioWorkletProcessor class
import { SuperpoweredWebAudio } from "../superpowered/SuperpoweredWebAudio.js";

class UserAudioProcessor extends SuperpoweredWebAudio.AudioWorkletProcessor {
  // Runs after the constructor
  onReady() {
    this.mixer = new this.Superpowered.MonoMixer();

    this.userInputVol = 0.5;
    // Pass an event object over to the main scope to tell it everything is ready
    this.sendMessageToMainScope({ event: "ready" });
  }

  // onDestruct is called when the parent AudioWorkletNode.destruct() method is called.
  // You should clear up all SP class instances here.
  onDestruct() {
    this.mixer.destruct();
  }

  onMessageFromMainScope(message) {
    if (message.type === "parameterChange") {
      if (message.payload?.id === "userInputVol")
        this.userInputVol = message.payload.value;
    }
  }

  processAudio(inputBuffer, outputBuffer, buffersize, parameters) {
    this.mixer.inputGain[0] = this.userInputVol;

    // Mixes up to 4 mono inputs into a mono output. Has no return value.
    this.mixer.process(
      inputBuffer.pointer, // Pointer to floating point numbers. 32-bit input buffer for the first input. Can be null.
      0, // Pointer to floating point numbers. 32-bit input buffer for the second input. Can be null.
      0, // Pointer to floating point numbers. 32-bit input buffer for the third input. Can be null.
      0, // Pointer to floating point numbers. 32-bit input buffer for the fourth input. Can be null.
      outputBuffer.pointer, // Pointer to floating point numbers. 32-bit output buffer.
      buffersize * 2 // Number of frames to process. Must be a multiple of 4.
    );
  }
}

// The following code registers the processor script in the browser, notice the label and reference
if (typeof AudioWorkletProcessor !== "undefined")
  registerProcessor("UserAudioProcessor", UserAudioProcessor);
export default UserAudioProcessor;
