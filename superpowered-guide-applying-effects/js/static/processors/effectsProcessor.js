import { SuperpoweredWebAudio } from "../superpowered/SuperpoweredWebAudio.js";

class EffectsProcessor extends SuperpoweredWebAudio.AudioWorkletProcessor {

  // Runs after the constructor.
  onReady() {
    this.reverb = new this.Superpowered.Reverb(
      this.samplerate,
      this.samplerate
    );
    this.reverb.enabled = true;
    this.reverb.mix = 0.5;

    this.filter = new this.Superpowered.Filter(
      this.Superpowered.Filter.Resonant_Lowpass,
      this.samplerate
    );
    this.filter.resonance = 0.2;
    this.filter.frequency = 2000;
    this.filter.enabled = true;

    this.inputGain = 0.2;
    this.previousInputGain = 0;

    // Notify the main scope that we're prepared.
    this.sendMessageToMainScope({ event: "ready" });
  }

  // onDestruct is called when the parent AudioWorkletNode.destruct() method is called.
  // You should clear up all Superpowered objects and allocated buffers here.
  onDestruct() {
    this.reverb.destruct();
    this.filter.destruct();
  }

  // Messages are received from the main scope through this method.
  onMessageFromMainScope(message) {
    if (message.type === "parameterChange") {
      if (message.payload?.id === "inputGain") this.inputGain = message.payload.value;
      else if (message.payload?.id === "reverbMix") this.reverb.mix = message.payload.value;
      else if (message.payload?.id === "filterFrequency") this.filter.frequency = message.payload.value;
    }
  }

  processAudio(inputBuffer, outputBuffer, buffersize, parameters) {
    // Ensure the samplerate is in sync on every audio processing callback.
    this.filter.samplerate = this.samplerate;
    this.reverb.samplerate = this.samplerate;

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

    // Apply reverb to output (in-place).
    this.reverb.process(outputBuffer.pointer, outputBuffer.pointer, buffersize);

    // Apply the filter (in-place).
    this.filter.process(outputBuffer.pointer, outputBuffer.pointer, buffersize);
  }
}

// The following code registers the processor script in the browser, please note the label and reference.
if (typeof AudioWorkletProcessor !== "undefined") registerProcessor("EffectsProcessor", EffectsProcessor);
export default EffectsProcessor;
