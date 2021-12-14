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
#import "SuperpoweredMixer.h"

@interface ViewController ()
@property (nonatomic, strong) SuperpoweredOSXAudioIO *superpowered;
@property (weak) IBOutlet NSButton *startButton;
@end

@implementation ViewController {
    Superpowered::Generator *generator1;
    Superpowered::Generator *generator2;
    Superpowered::Generator *generator3;
    Superpowered::MonoMixer *monoMixer;
    float globalVolume;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // First we intialise the Superpowered library
    Superpowered::Initialize(
     "ExampleLicenseKey-WillExpire-OnNextUpdate",
     false, // enableAudioAnalysis (using SuperpoweredAnalyzer, SuperpoweredLiveAnalyzer, SuperpoweredWaveform or SuperpoweredBandpassFilterbank)
     false, // enableFFTAndFrequencyDomain (using SuperpoweredFrequencyDomain, SuperpoweredFFTComplex, SuperpoweredFFTReal or SuperpoweredPolarFFT)
     false, // enableAudioTimeStretching (using SuperpoweredTimeStretching)
     true, // enableAudioEffects (using any SuperpoweredFX class)
     false, // enableAudioPlayerAndDecoder (using SuperpoweredAdvancedAudioPlayer or SuperpoweredDecoder)
     false, // enableCryptographics (using Superpowered::RSAPublicKey, Superpowered::RSAPrivateKey, Superpowered::hasher or Superpowered::AES)
     false  // enableNetworking (using Superpowered::httpRequest)
    );

    
    // Do any additional setup after loading the view.
    NSLog(@"Superpowered version: %u", Superpowered::Version());

    // Create the instances of the Generator classes, passing int he samplerate and initial wave type
    generator1 = new Superpowered::Generator(48000, Superpowered::Generator::Sine);
    generator2 = new Superpowered::Generator(48000, Superpowered::Generator::Sine);
    
    // Create the instance of the MonoMixer we'll be using to sum signals
    monoMixer = new Superpowered::MonoMixer();
    
    // Set the fixed gain values of the mixer channels
    monoMixer->inputGain[0] = 0.5;
    monoMixer->inputGain[1] = 0.5;
    
    // Set the frequency of the two generators
    generator1->frequency = 440;
    generator2->frequency = 660;
    

    // lastly , init the superpowered library with the OS level audio IO wrapper and start
    self.superpowered = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:true enableOutput:true];
    [self.superpowered start];
}

- (bool)audioProcessingCallback:(float **)inputBuffers inputChannels:(unsigned int)inputChannels outputBuffers:(float **)outputBuffers outputChannels:(unsigned int)outputChannels numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
    
    // First we create two buffers to store th output of the two generators before summing
    float gen1OutputBuffer[numberOfFrames];
    float gen2OutputBuffer[numberOfFrames];
    
    // Then we call the generate methods on the generator isntances, mono output created
    generator1->generate(gen1OutputBuffer, numberOfFrames);
    generator2->generate(gen2OutputBuffer, numberOfFrames);
    
    // The mono signals are then passed into the MonoMixer's first two channels. THe remainign channels are NULLEd out.
    monoMixer->process(
       gen1OutputBuffer, // Channel 1 - Generator 1 signal
       gen2OutputBuffer, // Channel 2 - Generator 2 signal
       NULL, // Channel 3 - unused
       NULL, // Channel 4 - unused
       outputBuffers[0], // Output
       numberOfFrames
    );
    
    // We need to copy the left channel to the right channel to make the stereo signal required for output
    memcpy(outputBuffers[1], outputBuffers[0], sizeof(float) * numberOfFrames);
    
    return true;
}

@end
