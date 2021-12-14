// Import the SuperpoweredWebAudio helper to allow us to extend the SuperpoweredWebAudio.AudioWorkletProcessor class
import { SuperpoweredWebAudio } from "../superpowered/SuperpoweredWebAudio.js";

class MixingSignalsProcessor extends SuperpoweredWebAudio.AudioWorkletProcessor {
  // Runs after the constructor
  onReady() {
    // Create an instance of a SP generator class to create pink noise
    this.generator1 = new this.Superpowered.Generator(
      this.samplerate, // The initial sample rate in Hz.
      this.Superpowered.Generator.Sine // The initial shape.
    );

    // Create an instance of a SP generator class to create a sine tone
    this.generator2 = new this.Superpowered.Generator(
      this.samplerate, // The initial sample rate in Hz.
      this.Superpowered.Generator.Sine // The initial shape.
    );

    // Create an instance of a Superpowered MonoMixer
    this.mixer = new this.Superpowered.MonoMixer();

    // Create two buffers to store the full scale output of each generator before summing in the mixer
    // An array of length 4096 is created to accomodate for the varying buffer sizes that is defined by
    // Superpowereds parent AudioContext.
    this.gen1OutputBuffer = new this.Superpowered.Float32Buffer(4096);
    this.gen2OutputBuffer = new this.Superpowered.Float32Buffer(4096);

    // Here we create a buffer to store the mono mixed signal before we convert it to an interleaved stero signal for output.
    this.monoMixerOutput = new this.Superpowered.Float32Buffer(4096);

    // Set the frequency of the first sine tone
    this.generator1.frequency = 440;
    // Set the frequency of the second sine tone a perfect fifth above
    this.generator2.frequency = 660;

    // Set the gain values of the MonoMixer we created
    this.mixer.inputGain[0] = 0.5;
    this.mixer.inputGain[1] = 0.5;

    // Pass an event object over to the main scope to tell it everything is ready
    this.sendMessageToMainScope({ event: "ready" });
  }

  // onDestruct is called when the parent AudioWorkletNode.destruct() method is called.
  // You should clear up all SP class instances here.
  onDestruct() {
    this.generator.destruct();
    this.generator2.destruct();
    this.mixer.destruct();
  }

  processAudio(inputBuffer, outputBuffer, buffersize, parameters) {
    // Generate the next buffer of the first generator
    // Point the output the holding buffer we made in onReady
    this.generator1.generate(
      this.gen1OutputBuffer.pointer, // output, // Pointer to floating point numbers. 32-bit MONO output.
      buffersize // we multiple this by two because .generate returns a mono signal whereas the outputBuffer is interleaved stereo.
    );

    // Generate the next buffer of the second generator
    // Point the output the holding buffer we made in onReady
    this.generator2.generate(
      this.gen2OutputBuffer.pointer, // output, // Pointer to floating point numbers. 32-bit MONO output.
      buffersize // we multiple this by two because .generate returns a mono signal whereas the outputBuffer is interleaved stereo.
    );

    // Mixes up to 4 mono inputs into a mono output. We only need to use two of them, the others are empty arrays.
    // Send output of this.mixer to the AudioWOrklet output buffer
    this.mixer.process(
      this.gen1OutputBuffer.pointer, // Pointer to floating point numbers. 32-bit input buffer for the first input. Can be null.
      this.gen2OutputBuffer.pointer, // Pointer to floating point numbers. 32-bit input buffer for the second input. Can be null.
      0, // null - no channel 3
      0, // null - no channel 4
      this.monoMixerOutput.pointer, // Pointer to floating point numbers. 32-bit output buffer.
      buffersize // Number of frames to process.
    );

    // Lasty, we must ALWAYS pass a stereo signal back to the parent AudioContext
    // So we use the Interleave utility to achieve this
    this.Superpowered.Interleave(
      this.monoMixerOutput.pointer, // left mono input
      this.monoMixerOutput.pointer, // right mono input
      outputBuffer.pointer, // stereo output - this is what is routed to the AudioWorkletProcessor output
      buffersize // number of frames
    );
  }
}

// The following code registers the processor script in the browser, notice the label and reference
if (typeof AudioWorkletProcessor !== "undefined")
  registerProcessor("MixingSignalsProcessor", MixingSignalsProcessor);
export default MixingSignalsProcessor;
