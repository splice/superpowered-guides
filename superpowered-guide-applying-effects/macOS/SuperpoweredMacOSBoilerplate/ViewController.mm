//
//  ViewController.m
//  SuperpoweredGuideCapturingAudio
//
//  Created by Balázs Kiss and Thomas Dodds on 2021. 10. 21..
//

#import "ViewController.h"
#import "Superpowered.h"
#import "SuperpoweredSimple.h"
#import "SuperpoweredOSXAudioIO.h"
#import "SuperpoweredFilter.h"
#import "SuperpoweredReverb.h"
#import "SuperpoweredMixer.h"
#import <atomic>

@interface ViewController ()
@property (nonatomic, strong) SuperpoweredOSXAudioIO *superpowered;
@property (weak) IBOutlet NSSlider *inputGainSlider;
@property (weak) IBOutlet NSSlider *reverbMixSlider;
@property (weak) IBOutlet NSSlider *filterFrequencySlider;

@end

@implementation ViewController {
    Superpowered::StereoMixer *stereoMixer;
    Superpowered::Filter *filter;
    Superpowered::Reverb *reverb;
    float inputGain, previousInputGain, reverbMix, filterFrequency;
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

    // Do any additional setup after loading the view.
    NSLog(@"Superpowered version: %u", Superpowered::Version());
    
    reverb = new Superpowered::Reverb(48000, 48000);
    filter = new Superpowered::Filter(
      Superpowered::Filter::FilterType::Resonant_Lowpass,
      48000
    );
    
    reverb->enabled = true;
    filter->enabled = true;
    
    inputGain = 0.2;
    previousInputGain = 0.2;
    

    self.superpowered = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:true enableOutput:true];
    [self setVariables];
    [self.superpowered start];
}

- (void)setVariables {
    inputGain = self.inputGainSlider.floatValue;
    filterFrequency = self.filterFrequencySlider.floatValue;
    reverbMix = self.reverbMixSlider.floatValue;
}

- (bool)audioProcessingCallback:(float **)inputBuffers inputChannels:(unsigned int)inputChannels outputBuffers:(float **)outputBuffers outputChannels:(unsigned int)outputChannels numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
    
    // Ensure the samplerate is in sync on every audio processing callback
    reverb->samplerate = samplerate;
    filter->samplerate = samplerate;

    // Render the output buffers

    // First we'll define an output buffer for our stereo input singal to be output to
    float stereoInputBuffer[numberOfFrames * 2];

    // THen we create that streo signal from the mono input signal
    Superpowered::Interleave(inputBuffers[0], inputBuffers[0], stereoInputBuffer, numberOfFrames);

    // We then apply the current values to the classes
    
    reverb->mix = reverbMix;
    filter->frequency = filterFrequency;

    // Then pass the stereoInputBuffer into a Volume utility
    Superpowered::Volume(stereoInputBuffer, stereoInputBuffer, previousInputGain, inputGain, numberOfFrames);
    previousInputGain = inputGain;
    
    // Apply reverb to input (in-place)
    reverb->process(stereoInputBuffer, stereoInputBuffer, numberOfFrames);
     
    // Apply the filter (in-place)
    filter->process(stereoInputBuffer, stereoInputBuffer, numberOfFrames);

    Superpowered::DeInterleave(stereoInputBuffer, outputBuffers[0], outputBuffers[1], numberOfFrames);

    return true;
}

- (IBAction)parmChanged:(id)sender {
    [self setVariables];
}

@end
