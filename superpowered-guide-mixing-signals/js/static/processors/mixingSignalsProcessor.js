import { SuperpoweredWebAudio } from "../superpowered/SuperpoweredWebAudio.js";

class MixingSignalsProcessor extends SuperpoweredWebAudio.AudioWorkletProcessor {

  // Runs after the constructor.
  onReady() {
    // Create the Generators and a MonoMixer to sum signals.
    this.generator1 = new this.Superpowered.Generator(
      this.samplerate,
      this.Superpowered.Generator.Sine
    );
    this.generator2 = new this.Superpowered.Generator(
      this.samplerate,
      this.Superpowered.Generator.Sine
    );
    this.mixer = new this.Superpowered.MonoMixer();

    // Pre-allocate some buffers for processing inside processAudio.
    // Allocating 1024 floats is safe, the buffer size is only 128 in most cases.
    this.gen1OutputBuffer = new this.Superpowered.Float32Buffer(4096);
    this.gen2OutputBuffer = new this.Superpowered.Float32Buffer(4096);
    this.monoMixerOutputBuffer = new this.Superpowered.Float32Buffer(4096);

    // Fixed gain values for the mixer channels.
    this.mixer.inputGain[0] = 0.5;
    this.mixer.inputGain[1] = 0.5;

    // Fixed frequencies for the two generators.
    this.generator1.frequency = 440;
    this.generator2.frequency = 660;

    // Notify the main scope that we're prepared.
    this.sendMessageToMainScope({ event: "ready" });
  }

  // onDestruct is called when the parent AudioWorkletNode.destruct() method is called.
  // You should clear up all Superpowered objects and allocated buffers here.
  onDestruct() {
    this.generator1.destruct();
    this.generator2.destruct();
    this.mixer.destruct();
    this.gen1OutputBuffer.free();
    this.gen2OutputBuffer.free();
    this.monoMixerOutputBuffer.free();
  }

  processAudio(inputBuffer, outputBuffer, buffersize, parameters) {
    // Ensure the samplerate is in sync on every audio processing callback.
    this.generator1.samplerate = this.samplerate;
    this.generator2.samplerate = this.samplerate;

    // Generate the first signal.
    this.generator1.generate(
      this.gen1OutputBuffer.pointer,
      buffersize
    );

    // Generate the second signal.
    this.generator2.generate(
      this.gen2OutputBuffer.pointer,
      buffersize
    );

    // Mix the two tones into another buffer.
    this.mixer.process(
      this.gen1OutputBuffer.pointer, // input 1
      this.gen2OutputBuffer.pointer, // input 2
      0,                             // input 3 (empty)
      0,                             // input 4 (empty)
      this.monoMixerOutputBuffer.pointer, // output
      buffersize
    );

    // Copy the mono buffer into the interleaved stereo output.
    this.Superpowered.Interleave(
      this.monoMixerOutputBuffer.pointer, // left side
      this.monoMixerOutputBuffer.pointer, // right side
      outputBuffer.pointer,
      buffersize
    );
  }
}

// The following code registers the processor script in the browser, please note the label and reference.
if (typeof AudioWorkletProcessor !== "undefined") registerProcessor("MixingSignalsProcessor", MixingSignalsProcessor);
export default MixingSignalsProcessor;
