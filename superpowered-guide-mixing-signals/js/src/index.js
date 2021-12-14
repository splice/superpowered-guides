import SuperpoweredGlue from "../static/superpowered/SuperpoweredGlueModule.js";
import { SuperpoweredWebAudio } from "../static/superpowered/SuperpoweredWebAudio.js";

// The  location of the superpowered WebAssembly library
const superPoweredWasmLocation = "/static/superpowered/superpowered.wasm";
// The  location of the processor from the browser to fetch
const mixingSignalsProcessorUrl =
  "/static/processors/mixingSignalsProcessor.js";
// The sample rate we'd like our AudioContext to operate at
const minimumSampleRate = 48000;

class DemoApplication {
  constructor() {
    this.webaudioManager = null;
    this.boot();
  }

  async boot() {
    await this.setupSuperpowered();
    await this.loadProcessor();
  }

  onMessageProcessorAudioScope = (message) => {
    // Here is where we receive serialisable message from the audio scope.
    // We're sending our own ready event payload when the proeccesor is fully innitialised
    if (message.event === "ready") {
      document.getElementById("startButton").disabled = false;
    }
  };

  async setupSuperpowered() {
    this.superpowered = await SuperpoweredGlue.fetch(superPoweredWasmLocation);
    this.superpowered.Initialize({
      licenseKey: "ExampleLicenseKey-WillExpire-OnNextUpdate",
      enableAudioAnalysis: true,
      enableFFTAndFrequencyDomain: true,
      enableAudioTimeStretching: true,
      enableAudioEffects: true,
      enableAudioPlayerAndDecoder: true,
      enableCryptographics: false,
      enableNetworking: false
    });
    this.webaudioManager = new SuperpoweredWebAudio(
      minimumSampleRate,
      this.superpowered
    );
  }

  async loadProcessor() {
    // Now create the AudioWorkletNode, passing in the AudioWorkletProcessor url, it's registered name (defined inside the processor) and a callback then gets called when everything is up a ready
    this.generatorProcessorNode = await this.webaudioManager.createAudioNodeAsync(
      mixingSignalsProcessorUrl,
      "MixingSignalsProcessor",
      this.onMessageProcessorAudioScope
    );

    // Connect the AudioWorkletNode to the WebAudio destination (speakers);
    this.generatorProcessorNode.connect(
      this.webaudioManager.audioContext.destination
    );
    this.webaudioManager.audioContext.suspend();
  }

  resumeContext() {
    console.log("resuming");
    this.webaudioManager.audioContext.resume();
    document.getElementById("startButton").style.display = "none";
  }
}

const demoApp = new DemoApplication();

// expose a function to the window so we can call it from the HTML markup
window.resumeContext = demoApp.resumeContext.bind(demoApp);
