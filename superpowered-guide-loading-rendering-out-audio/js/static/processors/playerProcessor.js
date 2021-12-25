// Import the SuperpoweredWebAudio helper to allow us to extend the SuperpoweredWebAudio.AudioWorkletProcessor class
import {
  SuperpoweredWebAudio,
  SuperpoweredTrackLoader
} from "../superpowered/SuperpoweredWebAudio.js";

class PlayerProcessor extends SuperpoweredWebAudio.AudioWorkletProcessor {
  // Runs after the constructor
  onReady() {
    this.mixer = new this.Superpowered.StereoMixer();
    this.player = new this.Superpowered.AdvancedAudioPlayer(
      this.samplerate,
      2,
      2,
      0,
      0.501,
      2,
      false
    );
    this.player.loopOnEOF = true;
    this.playerGain = 1;

    // Pass an event object over to the main scope to tell it everything is ready
    this.sendMessageToMainScope({ event: "ready" });
  }

  // onDestruct is called when the parent AudioWorkletNode.destruct() method is called.
  // You should clear up all SP class instances here.
  onDestruct() {
    this.player.destruct();
  }

  onMessageFromMainScope(message) {
    if (message.type === "command") {
      this.handleIncomingCommand(message);
    }
    if (message.type === "parameterChange") {
      if (message.payload.id === "localPlayerVolume") {
        this.playerGain = message.payload.value;
      }
      if (message.payload.id === "localPlayerRate") {
        this.player.playbackRate = message.payload.value;
      }
    }
    if (message.SuperpoweredLoaded) {
      this.player.pause();
      this.sampleLoaded = true;
      this.player.openMemory(
        this.Superpowered.arrayBufferToWASM(message.SuperpoweredLoaded.buffer),
        false,
        false
      );
      this.player.seek(0);
      this.player.play();
      this.sendMessageToMainScope({ event: "assetLoaded" });
    }
  }

  processAudio(inputBuffer, outputBuffer, buffersize, parameters) {
    if (
      !this.sampleLoaded ||
      !this.player.processStereo(outputBuffer.pointer, false, buffersize, 1)
    ) {
      for (let n = 0; n < buffersize * 2; n++) outputBuffer.array[n] = 0;
    }

    this.Superpowered.Volume(
      outputBuffer.pointer,
      outputBuffer.pointer,
      this.playerGain,
      this.playerGain,
      buffersize
    );
  }
}

// The following code registers the processor script in the browser, notice the label and reference
if (typeof AudioWorkletProcessor !== "undefined")
  registerProcessor("PlayerProcessor", PlayerProcessor);
export default PlayerProcessor;
