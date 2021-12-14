import SuperpoweredGlue from "../static/superpowered/SuperpoweredGlueModule.js";
import { SuperpoweredWebAudio } from "../static/superpowered/SuperpoweredWebAudio.js";

class DemoApplication {
  constructor() {
    this.webaudioManager = null;
    this.controlsRef = null;
    this.startButtonRef = null;
    this.userInputVolPeak = null;
    this.canvas = null;
    this.canvasContext = null;
    this.startApp = this.startApp.bind(this);
    this.requestData = this.requestData.bind(this);
    this.onMessageProcessorAudioScope = this.onMessageProcessorAudioScope.bind(
      this
    );
  }

  // First define a handler that will be called whenever this.sendMessageToMainScope is called from the AudioWorkletProcessor scope
  onMessageProcessorAudioScope(message) {
    if (message.event === "ready") {
      console.log(message);
    }
    if (message.data) {
      this.drawInputMeterCanvas(message.data.analyzerData.inputPeakDb);
      this.drawOutputMeterCanvas(message.data.analyzerData.outputPeakDb);
    }
  }

  drawInputMeterCanvas(peakValue) {
    this.inputCanvasContext.clearRect(0, 0, 100, 10);
    this.inputCanvasContext.fillRect(0, 0, 100 * peakValue, 10);
  }

  drawOutputMeterCanvas(peakValue) {
    this.outputCanvasContext.clearRect(0, 0, 100, 10);
    this.outputCanvasContext.fillRect(0, 0, 100 * peakValue, 10);
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

  requestData() {
    if (this.processorNode?.sendMessageToAudioScope) {
      this.processorNode.sendMessageToAudioScope({
        type: "dataAnalyzerRequest"
      });
    }

    window.requestAnimationFrame(this.requestData.bind(this));
  }

  onParamChange(id, value) {
    document.getElementById(id).innerHTML = value;
    // Here we send the new Reverb Size value over to the audio thread to be applied
    this.processorNode.sendMessageToAudioScope({
      type: "parameterChange",
      payload: {
        id,
        value: Number(value) // we should type cast here
      }
    });
  }

  async startApp() {
    this.controlsRef = document.getElementById("bootedControls");
    this.startButtonRef = document.getElementById("startButton");
    this.userInputVolPeak = document.getElementById("userInputVolPeak");
    this.inputCanvas = document.getElementById("inputPeakMeter");
    this.inputCanvasContext = this.inputCanvas.getContext("2d");
    this.outputCanvas = document.getElementById("outputPeakMeter");
    this.outputCanvasContext = this.outputCanvas.getContext("2d");
    this.inputCanvasContext.fillStyle = "#37aee6";
    this.outputCanvasContext.fillStyle = "#37aee6";
    const superPoweredWasmLocation = "/static/superpowered/superpowered.wasm";
    const minimumSampleRate = 48000;
    const analysisProcessorUrl = "/static/processors/analysisProcessor.js";
    // Now create the AudioWorkletNode, passing in the AudioWorkletProcessor url, it's registered name (defined inside the processor) and a callback then gets called when everything is up a ready

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

    await this.setupAudioCapture();
    // The location of the processor from the browser to fetch
    this.processorNode = await this.webaudioManager.createAudioNodeAsync(
      analysisProcessorUrl,
      "AnalysisProcessor",
      this.onMessageProcessorAudioScope
    );
    // connect our user audio input stream to the audio input of the processor node
    this.userInputMergerNode.connect(this.processorNode);

    // Connect the AudioWorkletNode to the WebAudio destination (speakers);
    this.processorNode.connect(this.webaudioManager.audioContext.destination);
    this.webaudioManager.audioContext.resume();

    //hide the start button
    this.startButtonRef.style.display = "none";
    //unhide the controls
    this.controlsRef.style.display = "flex";
    console.log("about to request");
    window.requestAnimationFrame(this.requestData);
  }
}

const demoApplication = new DemoApplication();

window.startApp = demoApplication.startApp.bind(demoApplication);
window.onParamChange = demoApplication.onParamChange.bind(demoApplication);
