// Import the SuperpoweredWebAudio helper to allow us to extend the SuperpoweredWebAudio.AudioWorkletProcessor class
import { SuperpoweredWebAudio } from "../superpowered/SuperpoweredWebAudio.js";

class EffectsProcessor extends SuperpoweredWebAudio.AudioWorkletProcessor {
  // Runs after the constructor
  onReady() {
    // Create FX A - an instance of Superpowered Reverb
    this.reverb = new this.Superpowered.Reverb(
      this.samplerate,
      this.samplerate
    );
    this.reverb.enabled = true;
    this.reverb.mix = 0.5;
    // Create FX B - an instance of Superpowered Filter
    this.filter = new this.Superpowered.Filter(
      this.Superpowered.Filter.Resonant_Lowpass,
      this.samplerate
    );
    this.filter.resonance = 0.2;
    this.filter.frequency = 2000;
    this.filter.enabled = true;

    // Set the initial input gain values
    this.inputGain = 0.2;
    // we need to set and get the previous gain value for use in the processAudio loop
    this.previousInputGain = 0.2;

    // Pass an event object over to the main scope to tell it everything is ready
    this.sendMessageToMainScope({ event: "ready" });
  }

  // onDestruct is called when the parent AudioWorkletNode.destruct() method is called.
  // You should clear up all SP class instances here.
  onDestruct() {
    this.reverb.destruct();
    this.filter.destruct();
  }

  // messages are received from the main scope through this method.
  onMessageFromMainScope(message) {
    // all incoming message from the main thread come through this handler
    // so we to filter the message type coming in
    if (message.type === "parameterChange") {
      if (message.payload?.id === "inputGain") {
        this.inputGain = message.payload.value;
      }
      if (message.payload?.id === "reverbMix") {
        this.reverb.mix = message.payload.value;
      }
      if (message.payload?.id === "filterFrequency") {
        this.filter.frequency = message.payload.value;
      }
    }
  }

  processAudio(inputBuffer, outputBuffer, buffersize, parameters) {

    // Ensure the samplerate is in sync on every audio processing callback
    this.filter.samplerate = this.samplerate;
    this.reverb.samplerate = this.samplerate;

    // Render the output buffers

    // Apply the input gain to the user input (supplied from the AudioWorkletProcessorNode input), via a volume function.
    this.Superpowered.Volume(
      inputBuffer.pointer,
      inputBuffer.pointer,
      this.previousInputGain,
      this.inputGain,
      buffersize
    );
    // The update the laest gain value applied for the next pocessAudio loop
    this.previousInputGain = this.inputGain;

    // Then take the output of the volume function and apply the reverb effect, replace the input buffer for the next effect (processing in place).
    this.reverb.process(inputBuffer.pointer, inputBuffer.pointer, buffersize);

    // Take in the input buffer which has reverb applied, then feed into the filter effect.
    // The output of the filter is set to the output buffer which is passed to the AudioWorkletProcessorNode input internally
    this.filter.process(inputBuffer.pointer, outputBuffer.pointer, buffersize);
  }
}

// The following code registers the processor script in the browser, notice the label and reference.
if (typeof AudioWorkletProcessor !== "undefined")
  registerProcessor("EffectsProcessor", EffectsProcessor);
export default EffectsProcessor;
