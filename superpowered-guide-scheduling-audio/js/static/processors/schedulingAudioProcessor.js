import { SuperpoweredWebAudio } from "../superpowered/SuperpoweredWebAudio.js";

class SchedulingAudioProcessor extends SuperpoweredWebAudio.AudioWorkletProcessor {

  // Runs after the constructor.
  onReady() {
    this.generator = new this.Superpowered.Generator(
      this.samplerate,
      this.Superpowered.Generator.Sine
    );

    // Pre-allocate a buffer for processing inside processAudio.
    // Allocating 1024 floats is safe, the buffer size is only 128 in most cases.
    this.monoBuffer = new this.Superpowered.Float32Buffer(4096);

    this.genVolume = 0;
    this.genPreviousVolume = 0;

    // Notify the main scope that we're prepared.
    this.sendMessageToMainScope({ event: "ready" });
  }

  // onDestruct is called when the parent AudioWorkletNode.destruct() method is called.
  // You should clear up all Superpowered objects and allocated buffers here.
  onDestruct() {
    this.generator.destruct();
    this.monoBuffer.free();
  }

  // Messages are received from the main scope through this method.
  onMessageFromMainScope(message) {
    if (message.type === "command") {
      if (message.payload?.id === "noteOn") {
        this.generator.frequency = message.payload.frequency;
        this.genVolume = message.payload.velocity;
      } else if (message.payload?.id === "noteOff") this.genVolume = message.payload.velocity;
    }
  }

  processAudio(inputBuffer, outputBuffer, buffersize, parameters) {
    // Ensure the samplerate is in sync on every audio processing callback.
    this.generator.samplerate = this.samplerate;

    // Generate the tone (full volume).
    this.generator.generate(
      this.monoBuffer.pointer,
      buffersize
    );

    // Copy the mono buffer into interleaved stereo buffer.
    this.Superpowered.Interleave(
      this.monoBuffer.pointer, // left side
      this.monoBuffer.pointer, // right side
      outputBuffer.pointer,
      buffersize
    );

    // Apply volume. genPreviousVolume is the start of the volume ramp, and genVolume is the destination of the ramp.
    // The ramp takes place over the length of the buffer (buffersize).
    this.Superpowered.Volume(
      outputBuffer.pointer,
      outputBuffer.pointer,
      this.genPreviousVolume,
      this.genVolume,
      buffersize
    );
    // Save the latest volume value which is used in the next process loop call.
    this.genPreviousVolume = this.genVolume;
  }
}

// The following code registers the processor script in the browser, please note the label and reference.
if (typeof AudioWorkletProcessor !== "undefined") registerProcessor("SchedulingAudioProcessor", SchedulingAudioProcessor);
export default SchedulingAudioProcessor;
