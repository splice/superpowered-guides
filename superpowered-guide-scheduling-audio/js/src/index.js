import SuperpoweredGlue from "../static/superpowered/SuperpoweredGlueModule.js";
import { SuperpoweredWebAudio } from "../static/superpowered/SuperpoweredWebAudio.js";

const superPoweredWasmLocation = "/static/superpowered/superpowered.wasm";
// The location of the processor from the browser to fetch
const schedulingAudioProcessorUrl = "/static/processors/schedulingAudioProcessor.js";

const minimumSampleRate = 48000;

class DemoApplication {
  constructor() {
    this.webaudioManager = null;
    this.generatorProcessorNode = null;
  }

  async startApp() {
    const superpowered = await SuperpoweredGlue.fetch(superPoweredWasmLocation);
    superpowered.Initialize({
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
      superpowered
    );

    // First define a handler that will be called whenever this.sendMessageToMainScope is called from the AudioWorkletProcessor scope
    // Remeber we called with a ready event so expect to see it here.

    const onMessageProcessorAudioScope = (message) => {
      if (message.event === "ready") {
        console.log(message);
      }
    };

    // Now create the AudioWorkletNode, passing in the AudioWorkletProcessor url, it's registered name (defined inside the processor) and a callback then gets called when everything is up a ready
    this.generatorProcessorNode = await this.webaudioManager.createAudioNodeAsync(
      schedulingAudioProcessorUrl,
      "SchedulingAudioProcessor",
      onMessageProcessorAudioScope
    );

    // Connect the AudioWorkletNode to the WebAudio destination (speakers);
    this.generatorProcessorNode.connect(
      this.webaudioManager.audioContext.destination
    );
    // this.webaudioManager.audioContext.suspend();
    document.getElementById("startButton").style.display = "none";
    document.getElementById("shonkyPiano").style.display = "flex";
  }

  startNote(freq) {
    this.generatorProcessorNode.sendMessageToAudioScope({
      type: "command",
      payload: {
        id: "noteOn",
        velocity: 0.5,
        frequency: freq
      }
    });
  }

  stopNote(freq) {
    this.generatorProcessorNode.sendMessageToAudioScope({
      type: "command",
      payload: {
        id: "noteOff",
        velocity: 0
      }
    });
  }
}

const demoApplication = new DemoApplication();

window.startApp = demoApplication.startApp.bind(demoApplication);
window.startNote = demoApplication.startNote.bind(demoApplication);
window.stopNote = demoApplication.stopNote.bind(demoApplication);
