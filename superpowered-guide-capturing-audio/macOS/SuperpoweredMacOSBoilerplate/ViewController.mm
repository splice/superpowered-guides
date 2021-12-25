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
#import <atomic>

@interface ViewController ()
@property (nonatomic, strong) SuperpoweredOSXAudioIO *superpowered;
@property (weak) IBOutlet NSSlider *inputGainSlider;

@end



@implementation ViewController {
    float inputGain, previousInputGain; // our local variable to store incomign changes from the Slider
}

- (void)viewDidLoad {
    [super viewDidLoad];

    Superpowered::Initialize(
     "ExampleLicenseKey-WillExpire-OnNextUpdate",
     false, // enableAudioAnalysis (using SuperpoweredAnalyzer, SuperpoweredLiveAnalyzer, SuperpoweredWaveform or SuperpoweredBandpassFilterbank)
     false, // enableFFTAndFrequencyDomain (using SuperpoweredFrequencyDomain, SuperpoweredFFTComplex, SuperpoweredFFTReal or SuperpoweredPolarFFT)
     false, // enableAudioTimeStretching (using SuperpoweredTimeStretching)
     true, // enableAudioEffects (using any SuperpoweredFX class)
     true, // enableAudioPlayerAndDecoder (using SuperpoweredAdvancedAudioPlayer or SuperpoweredDecoder)
     false, // enableCryptographics (using Superpowered::RSAPublicKey, Superpowered::RSAPrivateKey, Superpowered::hasher or Superpowered::AES)
     false  // enableNetworking (using Superpowered::httpRequest)
    );

    // Do any additional setup after loading the view.
    NSLog(@"Superpowered version: %u", Superpowered::Version());
    
    inputGain = 0.5;
    previousInputGain = 0.5;
    
    self.superpowered = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:true enableOutput:true];
    [self setVariables];
    [self.superpowered start];
}

- (void)setVariables {
        inputGain = self.inputGainSlider.floatValue;
}

- (bool)audioProcessingCallback:(float **)inputBuffers inputChannels:(unsigned int)inputChannels outputBuffers:(float **)outputBuffers outputChannels:(unsigned int)outputChannels numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
    
    float outputBuffer[numberOfFrames * 2];
    
    Superpowered::Interleave(inputBuffers[0], inputBuffers[0], outputBuffer, numberOfFrames);
    
    Superpowered::Volume(outputBuffer, outputBuffer, inputGain, previousInputGain, numberOfFrames);
    previousInputGain = inputGain;
    
    Superpowered::DeInterleave(outputBuffer, outputBuffers[0], outputBuffers[1], numberOfFrames);
    
    return true;
}
- (IBAction)parmChanged:(id)sender {
    [self setVariables];
}

@end
