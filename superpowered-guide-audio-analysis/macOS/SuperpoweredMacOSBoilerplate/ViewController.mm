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
@property (weak) IBOutlet NSLevelIndicator *inputLevelMeter;
@property (weak) IBOutlet NSLevelIndicator *outputLevelMeter;
@property (strong) NSTimer *timer;
@end



@implementation ViewController {
    Superpowered::StereoMixer *stereoMixer;
    Superpowered::Filter *filter;
    Superpowered::Reverb *reverb;
    std::atomic<bool> isUpdatingValues;
    std::atomic<float> inputGain, reverbMix, filterFrequency;
    std::atomic<float> inputPeak, outputPeak;
    
}

- (void)animate {
    [self.inputLevelMeter setDoubleValue: inputPeak * 10];
    [self.outputLevelMeter setDoubleValue: outputPeak * 10];
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
    
    stereoMixer = new Superpowered::StereoMixer();
    reverb = new Superpowered::Reverb(48000, 48000);
    filter = new Superpowered::Filter(
      Superpowered::Filter::FilterType::Resonant_Lowpass,
      48000
    );
    
    reverb->enabled = true;
    filter->enabled = true;
    
    stereoMixer->inputGain[0] = stereoMixer->inputGain[1] =  0.3;

    self.superpowered = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:true enableOutput:true];
    [self setVariables];
    [self.superpowered start];
    
    // Start Meter animaion loop (100fps)
    self.timer = [NSTimer timerWithTimeInterval:1.0/100.0 target:self selector:@selector(animate) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)setVariables {
    inputGain = self.inputGainSlider.floatValue;
    filterFrequency = self.filterFrequencySlider.floatValue;
    reverbMix = self.reverbMixSlider.floatValue;
}

- (bool)audioProcessingCallback:(float **)inputBuffers inputChannels:(unsigned int)inputChannels outputBuffers:(float **)outputBuffers outputChannels:(unsigned int)outputChannels numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
    
    reverb->mix = reverbMix;
    filter->frequency = filterFrequency;
    
    float outputBuffer[numberOfFrames * 2];
    
    
    Superpowered::Interleave(inputBuffers[0], inputBuffers[0], outputBuffer, numberOfFrames);
    
    inputPeak = (double) Superpowered::Peak(outputBuffer, numberOfFrames);
    
    Superpowered::Volume(outputBuffer, outputBuffer, inputGain, inputGain, numberOfFrames);
    
    
    
    // Apply reverb to input
    reverb->process(outputBuffer, outputBuffer, numberOfFrames);
    
    // Apply the filter
    filter->process(outputBuffer, outputBuffer, numberOfFrames);
    
    outputPeak = (double) Superpowered::Peak(outputBuffer, numberOfFrames);
    
    Superpowered::DeInterleave(outputBuffer, outputBuffers[0], outputBuffers[1], numberOfFrames);

    return true;
}
- (IBAction)parmChanged:(id)sender {
    [self setVariables];
}

@end

