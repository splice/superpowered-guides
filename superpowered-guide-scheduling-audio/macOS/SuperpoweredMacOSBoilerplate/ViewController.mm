//
//  ViewController.m
//  SuperpoweredMacOSBoilerplate
//
//  Created by Thomas Dodds and Balazs Kiss on 2021. 11. 18..
//

#import "ViewController.h"
#import "Superpowered.h"
#import "SuperpoweredSimple.h"
#import "SuperpoweredOSXAudioIO.h"
#import "SuperpoweredGenerator.h"
#import "CustomButton.h"
#import <atomic>

@interface ViewController ()
@property (nonatomic, strong) SuperpoweredOSXAudioIO *superpowered;
@property (weak) IBOutlet CustomButton *buttonA;
@property (weak) IBOutlet CustomButton *buttonB;
@property (weak) IBOutlet CustomButton *buttonC;
@property (weak) IBOutlet CustomButton *buttonD;
@end


@implementation ViewController {
    Superpowered::Generator *generator;
    float genVolume, genPreviousVolume;
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
    
    generator = new Superpowered::Generator(48000, Superpowered::Generator::Sine);

    genVolume = 0;
    genPreviousVolume = 0;

    self.superpowered = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:true enableOutput:true];
    [self.superpowered start];
    [self bindButtonActions];
}

- (void)bindButtonActions {
    self.buttonA.mouseDownBlock = ^{
        [self playNote:220];
    };
    self.buttonB.mouseDownBlock = ^{
        [self playNote:246.94];
    };
    self.buttonC.mouseDownBlock = ^{
        [self playNote:261.63];
    };
    self.buttonD.mouseDownBlock = ^{
        [self playNote:293.66];
    };
    self.buttonA.mouseUpBlock = self.buttonB.mouseUpBlock = self.buttonC.mouseUpBlock = self.buttonD.mouseUpBlock = ^{
        [self stopNote];
    };
}

-(void)playNote:(float) frequency {
    generator->frequency = frequency;
    genVolume = 0.5;
    NSLog(@"mouse down: %f", frequency);
}

-(void)stopNote {
    genVolume = 0;
    NSLog(@"mouse up");
}

- (bool)audioProcessingCallback:(float **)inputBuffers inputChannels:(unsigned int)inputChannels outputBuffers:(float **)outputBuffers outputChannels:(unsigned int)outputChannels numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
    
    float outputBuffer[numberOfFrames * 2];
    
    // Generate the full volume sine tone mono signal
    generator->generate(outputBuffers[0], numberOfFrames);
    
    // Create a stereo interlaved buffer which we can pass into the Volume utility
    Superpowered::Interleave(outputBuffers[0], outputBuffers[0], outputBuffer, numberOfFrames);
    
    // Here we apply genPreviousVolume as the start of the volume ramp
    // and genVolume as the destination of the ramp
    // The ramp takes place over the length of the buffer (numberOfFrames)
    Superpowered::Volume(
        outputBuffer,
        outputBuffer,
        genPreviousVolume,
        genVolume,
        numberOfFrames
    );
    // here we store the latest volume value which is used in the next process loop call.
    genPreviousVolume = genVolume;
    
    //We then convert the interleaved stereo format back into the format required by the OS
    Superpowered::DeInterleave(outputBuffer, outputBuffers[0], outputBuffers[1], numberOfFrames);

    return true;
}

@end
