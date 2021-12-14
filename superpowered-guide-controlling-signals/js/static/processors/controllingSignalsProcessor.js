// Import the SuperpoweredWebAudio helper to allow us to extend the SuperpoweredWebAudio.AudioWorkletProcessor class
import { SuperpoweredWebAudio } from "../superpowered/SuperpoweredWebAudio.js";

class ControllingSignalsProcessor extends SuperpoweredWebAudio.AudioWorkletProcessor {
  // Runs after the constructor
  onReady() {
    // Create an instance of a SP generator class
    this.generator1 = new this.Superpowered.Generator(
      this.samplerate, // The initial sample rate in Hz.
      this.Superpowered.Generator.Sine // The initial shape.
    );
    this.generator2 = new this.Superpowered.Generator(
      this.samplerate, // The initial sample rate in Hz.
      this.Superpowered.Generator.Sine // The initial shape.
    );

    // Create an instance of a Superpowered MonoMixer
    this.mixer = new this.Superpowered.MonoMixer();

    this.gen1OutputBuffer = new this.Superpowered.Float32Buffer(256); // A floating point number is 4 bytes, therefore we allocate length * 4 bytes of memory.
    this.gen2OutputBuffer = new this.Superpowered.Float32Buffer(256);
    this.generator1.frequency = 110;
    this.generator2.frequency = 220;

    this.gen1Volume = 0.5;
    this.gen2Volume = 0.5;

    // Pass an event object over to the main scope to tell it everything is ready
    this.sendMessageToMainScope({ event: "ready" });
  }

  // onDestruct is called when the parent AudioWorkletNode.destruct() method is called.
  // You should clear up all SP class instances here.
  onDestruct() {
    this.generator1.destruct();
    this.generator2.destruct();
  }

  onMessageFromMainScope(message) {
    if (message.type === "parameterChange") {
      if (message.payload?.id === "osc1Vol")
        this.gen1Volume = message.payload.value;
      if (message.payload?.id === "osc1Freq")
        this.generator1.frequency = message.payload.value;
      if (message.payload?.id === "osc2Vol")
        this.gen2Volume = message.payload.value;
      if (message.payload?.id === "osc2Freq")
        this.generator2.frequency = message.payload.value;
    }
  }

  processAudio(inputBuffer, outputBuffer, buffersize, parameters) {
    // generate the first signal
    this.generator1.generate(
      this.gen1OutputBuffer.pointer, // output, // Pointer to floating point numbers. 32-bit MONO output.
      buffersize * 2 // we multiple this by two becuase .generate returns a monto signal whereas the outputBuffer is interleaved stereo.
    );

    // generate the first signal
    this.generator2.generate(
      this.gen2OutputBuffer.pointer, // output, // Pointer to floating point numbers. 32-bit MONO output.
      buffersize * 2 // we multiple this by two becuase .generate returns a monto signal whereas the outputBuffer is interleaved stereo.
    );

    this.mixer.inputGain[0] = this.gen1Volume;
    this.mixer.inputGain[1] = this.gen2Volume;
    // Mixes up to 4 mono inputs into a mono output. Has no return value.
    this.mixer.process(
      this.gen1OutputBuffer.pointer, // Pointer to floating point numbers. 32-bit input buffer for the first input. Can be null.
      this.gen2OutputBuffer.pointer, // Pointer to floating point numbers. 32-bit input buffer for the second input. Can be null.
      0, // no input to channel 3
      0, // no input to channel 4
      outputBuffer.pointer, // Pointer to floating point numbers. 32-bit output buffer.
      buffersize * 2 // Number of frames to process. Must be a multiple of 4.
    );
  }
}

// The following code registers the processor script in the browser, notice the label and reference
if (typeof AudioWorkletProcessor !== "undefined")
  registerProcessor("ControllingSignalsProcessor", ControllingSignalsProcessor);
export default ControllingSignalsProcessor;
