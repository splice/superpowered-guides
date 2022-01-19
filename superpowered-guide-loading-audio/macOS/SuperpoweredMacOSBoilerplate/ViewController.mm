//
//  ViewController.m
//  SuperpoweredMacOSBoilerplate
//
//  Created by Balázs Kiss and Thomas Dodds on 2021. 10. 21..
//

#import "ViewController.h"
#import "Superpowered.h"
#import "SuperpoweredSimple.h"
#import "SuperpoweredOSXAudioIO.h"
#import "SuperpoweredAdvancedAudioPlayer.h"
#import <atomic>

@interface ViewController ()
@property (nonatomic, strong) SuperpoweredOSXAudioIO *superpowered;
@property (weak) IBOutlet NSSlider *localPlaybackRate;
@property (weak) IBOutlet NSSlider *localPlaybackPitch;
@property (weak) IBOutlet NSSlider *localGain;
@property (weak) IBOutlet NSSlider *remoteVolume;
@property (weak) IBOutlet NSButton *playLocalButton;
@property (weak) IBOutlet NSButton *playRemoteButton;

@end

@implementation ViewController {
    Superpowered::AdvancedAudioPlayer *playerA, *playerB;
    float localGainValue, localPlaybackRateValue, localPlaybackPitchValue, remoteGainValue;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    Superpowered::Initialize(
     "ExampleLicenseKey-WillExpire-OnNextUpdate",
     true, // enableAudioAnalysis (using SuperpoweredAnalyzer, SuperpoweredLiveAnalyzer, SuperpoweredWaveform or SuperpoweredBandpassFilterbank)
     true, // enableFFTAndFrequencyDomain (using SuperpoweredFrequencyDomain, SuperpoweredFFTComplex, SuperpoweredFFTReal or SuperpoweredPolarFFT)
     true, // enableAudioTimeStretching (using SuperpoweredTimeStretching)
     true, // enableAudioEffects (using any SuperpoweredFX class)
     true, // enableAudioPlayerAndDecoder (using SuperpoweredAdvancedAudioPlayer or SuperpoweredDecoder)
     false, // enableCryptographics (using Superpowered::RSAPublicKey, Superpowered::RSAPrivateKey, Superpowered::hasher or Superpowered::AES)
     false  // enableNetworking (using Superpowered::httpRequest)
    );
    NSLog(@"Superpowered version: %u", Superpowered::Version());
    
    
    // First let Superpowered know where it can store is temporary files used for buffereing HLS
    Superpowered::AdvancedAudioPlayer::setTempFolder([NSTemporaryDirectory() fileSystemRepresentation]);
    
    // Create two instances of the AdvancedAudioPlayer class, which we'll use to play our local and HLS stream
    playerA = new Superpowered::AdvancedAudioPlayer(48000, 0);
    playerB = new Superpowered::AdvancedAudioPlayer(48000, 0);
    
    
    // Tell the first player to open a local file
    playerA->open([[[NSBundle mainBundle] pathForResource:@"lycka" ofType:@"mp3"] fileSystemRepresentation]);
    
    // Tell the second player to open remote HLS stream (apple HLS test stream)
    playerB->openHLS("http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8");
    // Set the maximum buffer size in seconds
    playerB->HLSBufferingSeconds = 20;
    // Fast forward in the stream a bi before playback
    playerB->setPosition(6000, true, false);
    
    // Set current atomic floats from the UI sliders
    [self setVariables];

    // Setup superpowered
    self.superpowered = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:false enableOutput:true];
    
    // Start the scheduling of audioProcessingCallback
    [self.superpowered start];
}

- (bool)audioProcessingCallback:(float **)inputBuffers inputChannels:(unsigned int)inputChannels outputBuffers:(float **)outputBuffers outputChannels:(unsigned int)outputChannels numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
  
    // Ensure the samplerate is in sync on every audio processing callback
    playerA->samplerate = samplerate;
    playerB->samplerate = samplerate;

        // Render the output buffers
    // Our output buffer (which we'll convert later)
    float outputBuffer[numberOfFrames * 2];
  
    // Set the playback rate of the PlayerA to current atomic variable value
    playerA->playbackRate = localPlaybackRateValue;
    playerA->pitchShiftCents = localPlaybackPitchValue;
    
    // Check player statuses. We're only interested in the Opened event in this example.
    if (playerA->getLatestEvent() == Superpowered::AdvancedAudioPlayer::PlayerEvent_Opened) {
        // allow the user to click the play button for playerA
        self.playLocalButton.enabled = true;
    };
   
    // Store the output of player A into out outputbuffer, checking if it creates silence along the way
    bool silence = !playerA->processStereo(outputBuffer, false, numberOfFrames, localGainValue);
    
    // If silence, then write player B to the output buffer
    // If no silence, set the mix parameter of playerB's processStereo to true to mix its output into playerA's output
    if (playerB->processStereo(outputBuffer, !silence, numberOfFrames, remoteGainValue)) silence = false;
    
    // The output buffer is ready now, let's put the finished audio into the left and right outputs.
    if (!silence) Superpowered::DeInterleave(outputBuffer, outputBuffers[0], outputBuffers[1], numberOfFrames);
    return !silence;
}

- (IBAction)playLocalAudio:(id)sender {
    // Check we are able to play local file
    if (self.playLocalButton.enabled) {
        playerA->play();
        self.playLocalButton.enabled = false;
    }
}

- (IBAction)playRemote:(id)sender {
    playerB->play();
    self.playRemoteButton.enabled = false;
}

- (IBAction)updateParams:(id)sender {
    [self setVariables];
}

- (void)setVariables {
    localGainValue =  self.localGain.floatValue;
    localPlaybackRateValue =  self.localPlaybackRate.floatValue;
    localPlaybackPitchValue =  self.localPlaybackPitch.floatValue;
    remoteGainValue =  self.remoteVolume.floatValue;
}

@end
