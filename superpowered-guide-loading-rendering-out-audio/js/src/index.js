import SuperpoweredGlue from "../static/superpowered/SuperpoweredGlueModule.js";
import {
  SuperpoweredWebAudio,
  SuperpoweredTrackLoader
} from "../static/superpowered/SuperpoweredWebAudio.js";

const superPoweredWasmLocation = "/static/superpowered/superpowered.wasm";
const playerProcessorUrl = "/static/processors/playerProcessor.js";

const minimumSampleRate = 48000;

function make_download(abuffer, total_samples) {

	// get duration and sample rate
	var duration = abuffer.duration,
		rate = abuffer.sampleRate,
		offset = 0;

	var new_file = URL.createObjectURL(bufferToWave(abuffer, total_samples));

	var download_link = document.getElementById("download_link");
	download_link.href = new_file;
	var name = generateFileName();
	download_link.download = name;

}

function generateFileName() {
  var origin_name = 'offlineRender.wav';
  var pos = origin_name.lastIndexOf('.');
  var no_ext = origin_name.slice(0, pos);

  return no_ext + ".wav";
}


// Convert an AudioBuffer to a Blob using WAVE representation
function bufferToWave(abuffer, len) {
  var numOfChan = abuffer.numberOfChannels,
      length = len * numOfChan * 2 + 44,
      buffer = new ArrayBuffer(length),
      view = new DataView(buffer),
      channels = [], i, sample,
      offset = 0,
      pos = 0;

  // write WAVE header
  setUint32(0x46464952);                         // "RIFF"
  setUint32(length - 8);                         // file length - 8
  setUint32(0x45564157);                         // "WAVE"

  setUint32(0x20746d66);                         // "fmt " chunk
  setUint32(16);                                 // length = 16
  setUint16(1);                                  // PCM (uncompressed)
  setUint16(numOfChan);
  setUint32(abuffer.sampleRate);
  setUint32(abuffer.sampleRate * 2 * numOfChan); // avg. bytes/sec
  setUint16(numOfChan * 2);                      // block-align
  setUint16(16);                                 // 16-bit (hardcoded in this demo)

  setUint32(0x61746164);                         // "data" - chunk
  setUint32(length - pos - 4);                   // chunk length

  // write interleaved data
  for(i = 0; i < abuffer.numberOfChannels; i++)
    channels.push(abuffer.getChannelData(i));

  while(pos < length) {
    for(i = 0; i < numOfChan; i++) {             // interleave channels
      sample = Math.max(-1, Math.min(1, channels[i][offset])); // clamp
      sample = (0.5 + sample < 0 ? sample * 32768 : sample * 32767)|0; // scale to 16-bit signed int
      view.setInt16(pos, sample, true);          // write 16-bit sample
      pos += 2;
    }
    offset++                                     // next source sample
  }

  // create Blob
  return new Blob([buffer], {type: "audio/wav"});

  function setUint16(data) {
    view.setUint16(pos, data, true);
    pos += 2;
  }

  function setUint32(data) {
    view.setUint32(pos, data, true);
    pos += 4;
  }
}





class DemoApplication {
  constructor() {
    this.webaudioManager = null;
    this.processorNode = null;
    this.startButtonRef = document.getElementById("startButton");
    this.playerVolumeRef = document.getElementById("playerVolumeSlider");
    this.playerSpeedRef = document.getElementById("playerSpeedSlider");
    this.loadAssetButtonRef = document.getElementById("loadAssetButton");
    this.trackLoadingStatusRef = document.getElementById("trackLoadStatus");
    this.downloadButton = document.getElementById("download_link");
    this.startApp();
  }

  onMessageProcessorAudioScope(message) {
    if (message.event === "ready") {
      // The processor node is now loaded
      this.playerVolumeRef.disabled = false;
      this.playerSpeedRef.disabled = false;
    }
    if (message.event === "assetLoaded") {
      this.trackLoadingStatusRef.innerHTML = "Rendering audio offline...";
      
      this.loadAssetButtonRef.style.display = "none";
      this.playerVolumeRef.disabled = false;
      this.playerSpeedRef.disabled = false;
      // this.trackLoadingStatusRef.style.display = "none";
      this.webaudioManager.audioContext.resume();

    }
  }

  onParamChange(id, value) {
    this.processorNode.sendMessageToAudioScope({
      type: "parameterChange",
      payload: {
        id,
        value
      }
    });
  }


  make_download(abuffer, total_samples) {

    // get duration and sample rate
    var duration = abuffer.duration,
      rate = abuffer.sampleRate,
      offset = 0;
      
    var new_file = URL.createObjectURL(bufferToWave(abuffer, total_samples));
  
    var download_link = document.getElementById("download_link");
    download_link.href = new_file;
    var name = generateFileName();
    download_link.download = name;
   
  
  }
  
  generateFileName() {
    var origin_name = 'offlineRender.wav';
    var pos = origin_name.lastIndexOf('.');
    var no_ext = origin_name.slice(0, pos);
  
    return no_ext + ".wav";
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
      superpowered,
      {
        length: minimumSampleRate * 120,
      }
    );

    // Now create the AudioWorkletNode, passing in the AudioWorkletProcessor url, it's registered name (defined inside the processor) and a callback then gets called when everything is up a ready
    this.processorNode = await this.webaudioManager.createAudioNodeAsync(
      playerProcessorUrl,
      "PlayerProcessor",
      this.onMessageProcessorAudioScope.bind(this)
    );
    this.processorNode.onprocessorerror = (e) => {
      console.error(e);
    };
    this.webaudioManager.audioContext.suspend(0);
    this.webaudioManager.audioContext.startRendering().then((renderedBuffer) => {
      console.log('Rendering completed successfully', renderedBuffer);
      // var song = this.webaudioManager.audioContext.createBufferSource();
      // song.buffer = renderedBuffer;

      make_download(renderedBuffer, minimumSampleRate * 120);
      var downloadButton = document.getElementById('download-button');
      downloadButton.style.display = 'block';
      this.trackLoadingStatusRef.innerHTML = "Audio successfully rendered.";

      // song.connect(audioCtx.destination);

      // play.onclick = function() {
      //   song.start();
      // }
    }).catch(function(err) {
        console.log('Rendering failed: ' + err);
        // Note: The promise should reject when startRendering is called a second time on an OfflineAudioContext
    });

    
    // Connect the AudioWorkletNode to the WebAudio destination (speakers);
    this.processorNode.connect(this.webaudioManager.audioContext.destination);
    // this.processorNode.connect(this.offlineAudioContext.destination);

    
  }

  loadTrack() {
    this.trackLoadingStatusRef.innerHTML = "Downloading and decoding track...";
    // this.webaudioManager.audioContext.resume();
    const loadedCallback = this.processorNode.sendMessageToAudioScope.bind(
      this.processorNode
    );
    SuperpoweredTrackLoader.downloadAndDecode(
      "/static/audio/lycka.mp3",
      loadedCallback
    );
  }
}

const demoApplication = new DemoApplication();

//exposes methods to window for UI
window.startApp = demoApplication.startApp.bind(demoApplication);
window.loadTrack = demoApplication.loadTrack.bind(demoApplication);
window.onParamChange = demoApplication.onParamChange.bind(demoApplication);
