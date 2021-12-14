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
#import "SuperpoweredGenerator.h"
#import "SuperpoweredAdvancedAudioPlayer.h"
#import <atomic>


// some HLS stream url-title pairs
//static const char *urls[8] = {
//    "https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8", "Apple Advanced Example Stream",
//    "http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8", "Back to the Mac",
//    "http://playertest.longtailvideo.com/adaptive/bbbfull/bbbfull.m3u8", "JW Player Test",
//    "http://playertest.longtailvideo.com/adaptive/oceans_aes/oceans_aes.m3u8", "JW AES Encrypted",
//};

@interface ViewController ()
@property (nonatomic, strong) SuperpoweredOSXAudioIO *superpowered;
@property (weak) IBOutlet NSSlider *localPlaybackRate;
@property (weak) IBOutlet NSSlider *localGain;
@property (weak) IBOutlet NSTextField *localTempo;
@property (weak) IBOutlet NSSlider *remoteVolume;
@property (weak) IBOutlet NSTextField *remoteUrl;
@property (weak) IBOutlet NSButton *playLocalButton;
@property (weak) IBOutlet NSButton *playRemoteButton;

@end

@implementation ViewController {
    Superpowered::AdvancedAudioPlayer *playerA, *playerB;
    
    std::atomic<float> localGainValue, localTempoValue, remoteGainValue;
    
    bool playingA, playingB, localReady, remoteReady;
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
    
    Superpowered::AdvancedAudioPlayer::setTempFolder([NSTemporaryDirectory() fileSystemRepresentation]);

    // Do any additional setup after loading the view.
    NSLog(@"Superpowered version: %u", Superpowered::Version());
    
    playerA = new Superpowered::AdvancedAudioPlayer(48000, 0);
    playerB = new Superpowered::AdvancedAudioPlayer(48000, 0);
    
    playerA->open([[[NSBundle mainBundle] pathForResource:@"lycka" ofType:@"mp3"] fileSystemRepresentation]);
    
    playerB->openHLS("http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8");
    
    [self setVariables];
    
//    triggerPlay.enabled = false;

    self.superpowered = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:true enableOutput:true];
    [self.superpowered start];
}

- (bool)audioProcessingCallback:(float **)inputBuffers inputChannels:(unsigned int)inputChannels outputBuffers:(float **)outputBuffers outputChannels:(unsigned int)outputChannels numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
  
    float outputBuffer[numberOfFrames * 2];
  
    playerA->playbackRate = localTempoValue;
    
    // Check player statuses. We're only interested in the Opened event in this example.
    if (playerA->getLatestEvent() == Superpowered::AdvancedAudioPlayer::PlayerEvent_Opened) {
        localReady = true;
        self.playLocalButton.enabled = true;
    };
    if (playerB->getLatestEvent() == Superpowered::AdvancedAudioPlayer::PlayerEvent_Opened) {
        remoteReady = true;
        self.playRemoteButton.enabled = true;
    };

    bool silence = !playerA->processStereo(outputBuffer, false, numberOfFrames, localGainValue);
    
    if (playerB->processStereo(outputBuffer, !silence, numberOfFrames, remoteGainValue)) silence = false;
    // The output buffer is ready now, let's put the finished audio into the left and right outputs.
    if (!silence) Superpowered::DeInterleave(outputBuffer, outputBuffers[0], outputBuffers[1], numberOfFrames);
    return !silence;
}

- (IBAction)playLocalAudio:(id)sender {
    if (localReady) {
        playerA->play();
        playingA = true;
    }
}

- (IBAction)playRemote:(id)sender {
    if (remoteReady) {
        playerB->play();
        playingB = true;
    }
}


- (IBAction)updateParams:(id)sender {
    [self setVariables];
}



- (void)setVariables {
    localGainValue =  self.localGain.floatValue;
    localTempoValue =  self.localPlaybackRate.floatValue;
    remoteGainValue =  self.remoteVolume.floatValue;
}

@end
