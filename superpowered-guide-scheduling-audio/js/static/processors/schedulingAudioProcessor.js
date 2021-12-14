// Import the SuperpoweredWebAudio helper to allow us to extend the SuperpoweredWebAudio.AudioWorkletProcessor class
import { SuperpoweredWebAudio } from "../superpowered/SuperpoweredWebAudio.js";


class SchedulingAudioProcessor extends SuperpoweredWebAudio.AudioWorkletProcessor {
  // Runs after the constructor
  onReady() {
    // Create an instance of a SP generator class
    this.generator = new this.Superpowered.Generator(
      this.samplerate, // The initial sample rate in Hz.
      this.Superpowered.Generator.Sine // The initial shape.
    );

    this.genOutputBuffer = new this.Superpowered.Float32Buffer(4096); // A floating point number is 4 bytes, therefore we allocate length * 4 bytes of memory.
    this.interleavedOutput = new this.Superpowered.Float32Buffer(4096);

    this.genVolume = 0;
    this.genVolumePreviousVolume = 0;

    // Pass an event object over to the main scope to tell it everything is ready
    this.sendMessageToMainScope({ event: "ready" });
    console.log('whoop');
  }

  // onDestruct is called when the parent AudioWorkletNode.destruct() method is called.
  // You should clear up all SP class instances here.
  onDestruct() {
    this.generator.destruct();
  }

  onMessageFromMainScope(message) {
    
    if (message.type === "command") {
      if (message.payload?.id === "noteOn") {
        this.generator.frequency = message.payload.frequency;
        this.genVolume = message.payload.velocity;
      }
      if (message.payload?.id === "noteOff") {
        this.genVolume = message.payload.velocity;
      }
    }
  }

  processAudio(inputBuffer, outputBuffer, buffersize, parameters) {
    // generate the first signal
    this.generator.generate(
      this.genOutputBuffer.pointer, // output, // Pointer to floating point numbers. 32-bit MONO output.
      buffersize // we multiple this by two becuase .generate returns a monto signal whereas the outputBuffer is interleaved stereo.
    );

    this.Superpowered.Interleave(
      this.genOutputBuffer.pointer,
      this.genOutputBuffer.pointer,
      this.interleavedOutput.pointer,
      buffersize
    );

    // apply a volume manipulation to the first signal
    this.Superpowered.Volume(
      this.interleavedOutput.pointer,
      outputBuffer.pointer,
      this.genVolumePreviousVolume,
      this.genVolume,
      buffersize
    );
    this.genVolumePreviousVolume = this.genVolume;
  }
}

// The following code registers the processor script in the browser, notice the label and reference
if (typeof AudioWorkletProcessor !== "undefined")
  registerProcessor("SchedulingAudioProcessor", SchedulingAudioProcessor);
export default SchedulingAudioProcessor;
