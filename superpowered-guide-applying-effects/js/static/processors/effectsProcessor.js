// Import the SuperpoweredWebAudio helper to allow us to extend the SuperpoweredWebAudio.AudioWorkletProcessor class
import { SuperpoweredWebAudio } from "../superpowered/SuperpoweredWebAudio.js";

class EffectsProcessor extends SuperpoweredWebAudio.AudioWorkletProcessor {
  // Runs after the constructor
  onReady() {
    this.stereoMixer = new this.Superpowered.StereoMixer();
    this.stereoMixerOutputBuffer = new this.Superpowered.Float32Buffer(4096); // A buffer to store Gen2 full volume output
    // Create FX A - an instance of Superpowered Reverb
    this.reverb = new this.Superpowered.Reverb(
      this.samplerate,
      this.samplerate
    );
    this.reverb.enabled = true;

    // Create FX B - an instance of Superpowered Filter
    this.filter = new this.Superpowered.Filter(
      this.Superpowered.Filter.Resonant_Lowpass,
      this.samplerate
    );
    this.filter.resonance = 0.2;
    this.filter.frequency = 4000;
    this.filter.enabled = true;

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
        this.stereoMixer.inputGain[0] = message.payload.value;
        this.stereoMixer.inputGain[1] = message.payload.value;
      }
      if (message.payload?.id === "reverbSize") {
        this.reverb.roomSize = message.payload.value;
      }
      if (message.payload?.id === "filterFrequency") {
        this.filter.frequency = message.payload.value;
      }
    }
  }

  processAudio(inputBuffer, outputBuffer, buffersize, parameters) {
    // First lets apply the input gain to the user input (supplied from the AudioWorkletProcessorNode input), via the mixer.
    this.stereoMixer.process(
      inputBuffer.pointer,
      0,
      0,
      0,
      this.stereoMixerOutputBuffer.pointer,
      buffersize
    );
    // Then take the output of the mixer buffer and apply the reverb effect, replace the input buffer for the next effect (processing in place).
    this.reverb.process(
      this.stereoMixerOutputBuffer.pointer,
      this.stereoMixerOutputBuffer.pointer,
      buffersize
    );

    // Take in the input buffer which has reverb applied, then feed into the filter effect.
    // The output of the filter is set to the output buffer which is passed to the AudioWorkletProcessorNode input internally
    this.filter.process(
      this.stereoMixerOutputBuffer.pointer,
      outputBuffer.pointer,
      buffersize
    );
  }
}

// The following code registers the processor script in the browser, notice the label and reference
if (typeof AudioWorkletProcessor !== "undefined")
  registerProcessor("EffectsProcessor", EffectsProcessor);
export default EffectsProcessor;
