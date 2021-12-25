// Import the SuperpoweredWebAudio helper to allow us to extend the SuperpoweredWebAudio.AudioWorkletProcessor class
import { SuperpoweredWebAudio } from "../superpowered/SuperpoweredWebAudio.js";

class MeteringProcessor extends SuperpoweredWebAudio.AudioWorkletProcessor {
  // Runs after the constructor
  onReady() {
    this.reverb = new this.Superpowered.Reverb(
      this.samplerate, // The initial sample rate in Hz.
      this.samplerate // Maximum sample rate (affects memory usage, the lower the smaller).
    );

    this.inputFilter = new this.Superpowered.Filter(
      this.Superpowered.Filter.Resonant_Highpass,
      this.samplerate
    );
    this.inputFilter.frequency = 1000;
    this.inputFilter.enabled = true;

    this.reverb.mix = 0.5;
    this.reverb.enabled = true;

    this.inputGain = 0.4;
    this.previousInputGain = 0.4;
    this.inputPeakValue = 0;
    this.outputPeakValue = 0;

    // Pass an event object over to the main scope to tell it everything is ready
    this.sendMessageToMainScope({ event: "ready" });
  }

  // onDestruct is called when the parent AudioWorkletNode.destruct() method is called.
  // You should clear up all SP class instances here.
  onDestruct() {
    this.inputFilter.destruct();
    this.reverb.destruct();
  }

  onMessageFromMainScope(message) {
    console.log(message);
    if (message.type === "parameterChange") {
      if (message.payload?.id === "inputGain")
        this.inputGain = message.payload.value;
      if (message.payload?.id === "userInputFilterFreq")
        this.inputFilter.frequency = message.payload.value;
      if (message.payload?.id === "userInputReverbMix")
        this.reverb.mix = message.payload.value;
    }
    if (message.type === "dataAnalyzerRequest") {
      this.sendMessageToMainScope({
        data: {
          analyzerData: {
            inputPeakDb: this.inputPeakValue,
            outputPeakDb: this.outputPeakValue
          }
        }
      });
    }
  }

  processAudio(inputBuffer, outputBuffer, buffersize, parameters) {
    //pass the raw user singal through the analyzer
    this.inputPeakValue = this.Superpowered.Peak(
      inputBuffer, // Pointer to floating point numbers. 32-bit interleaved stereo input.
      buffersize // Number of frames to process.
    );

    // Apply the input gain to the user input (processing-in-place)
    this.Superpowered.Volume(
      inputBuffer.pointer,
      inputBuffer.pointer,
      this.previousInputGain,
      this.inputGain,
      buffersize
    );
    // Keep track of the previous gain value for the next processAudio loop.
    this.previousInputGain = this.inputGain;

    // aplly the filter to the user input in place
    this.inputFilter.process(
      inputBuffer.pointer,
      inputBuffer.pointer,
      buffersize
    );

    // apply the reverb effec to the filtered user input channel
    this.reverb.process(inputBuffer.pointer, outputBuffer.pointer, buffersize);

    this.outputPeakValue = this.Superpowered.Peak(
      outputBuffer, // Pointer to floating point numbers. 32-bit interleaved stereo input.
      buffersize // Number of frames to process.
    );
  }
}

// The following code registers the processor script in the browser, notice the label and reference
if (typeof AudioWorkletProcessor !== "undefined")
  registerProcessor("MeteringProcessor", MeteringProcessor);
export default MeteringProcessor;
