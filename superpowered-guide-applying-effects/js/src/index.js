import SuperpoweredGlue from "../static/superpowered/SuperpoweredGlueModule.js";
import { SuperpoweredWebAudio } from "../static/superpowered/SuperpoweredWebAudio.js";

// The  location of the superpowered WebAssembly library
const superPoweredWasmLocation = "/static/superpowered/superpowered.wasm";
// The  location of the processor from the browser to fetch
const effetcsProcessorUrl = "/static/processors/effectsProcessor.js";
// The sample rate we'd like our AudioContext to operate at
const minimumSampleRate = 48000;

class DemoApplication {
  constructor() {
    this.webaudioManager = null;
    this.userInputMergerNode = null;
  }

  async boot() {
    await this.setupSuperpowered();
  }

  onMessageProcessorAudioScope = (message) => {
    // Here is where we receive serialisable message from the audio scope.
    // We're sending our own ready event payload when the proeccesor is fully innitialised
    if (message.event === "ready") {
      document.getElementById("startButton").style.display = "none";
      document.getElementById("bootedControls").style.display = "flex";
    }
  };

  onParamChange = (id, value) => {
    document.getElementById(id).innerHTML = value;

    // Here we send the new Reverb Size value over to the audio thread to be applied
    this.processorNode.sendMessageToAudioScope({
      type: "parameterChange",
      payload: {
        id,
        value: Number(value) // we should type cast here
      }
    });
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

    await this.setupAudioCapture();
    // Now create the AudioWorkletNode, passing in the AudioWorkletProcessor url, it's registered name (defined inside the processor) and a callback then gets called when everything is up a ready
    this.processorNode = await this.webaudioManager.createAudioNodeAsync(
      effetcsProcessorUrl,
      "EffectsProcessor",
      this.onMessageProcessorAudioScope
    );

    // connect our user audio input stream to the audio input of the processor node
    this.userInputMergerNode.connect(this.processorNode);

    // Connect the AudioWorkletNode to the WebAudio destination (speakers);
    this.processorNode.connect(this.webaudioManager.audioContext.destination);
    this.webaudioManager.audioContext.resume();
  }

  async setupAudioCapture() {
    // either pass in {'fastAndTransparentAudio':true} for the default soundcard/device with no processing, (mono/channel 1)
    // or pass in a MediaStreamConstraints object - see https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamConstraints
    const userInputStream = await this.webaudioManager.getUserMediaForAudioAsync(
      {
        fastAndTransparentAudio: true
      }
    );
    if (!userInputStream) throw Error("Could no access user microphone");

    // We then create a WebAudio API MediaStreamSourceNode - https://developer.mozilla.org/en-US/docs/Web/API/MediaStreamAudioSourceNode
    const userInputStreamSourceNode = this.webaudioManager.audioContext.createMediaStreamSource(
      userInputStream
    );

    // If the input is mono (by default), then upmix the mono channel to a stereo node with a WebAudio API ChannelMergerNode.
    // This is to prepare the signal to be passed into Superpowered
    this.userInputMergerNode = this.webaudioManager.audioContext.createChannelMerger(
      2
    );
    // connec the userInputStreamSourceNode input to channels 0 and 1 (L and R)
    userInputStreamSourceNode.connect(this.userInputMergerNode, 0, 0);
    userInputStreamSourceNode.connect(this.userInputMergerNode, 0, 1);

    // from here we now have a stereo audio node (userInputMergerNode) which we can connect to an AudioWorklet Node
  }

  resumeContext() {
    this.webaudioManager.audioContext.resume();
  }
}

const demoApp = new DemoApplication();

// expose a function to the window so we can call it from the HTML markup
window.resumeContext = demoApp.resumeContext.bind(demoApp);

window.onParamChange = demoApp.onParamChange.bind(demoApp);

window.boot = demoApp.boot.bind(demoApp);
