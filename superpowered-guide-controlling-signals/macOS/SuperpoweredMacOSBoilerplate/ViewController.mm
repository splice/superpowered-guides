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
#import <atomic>

@interface ViewController ()
@property (nonatomic, strong) SuperpoweredOSXAudioIO *superpowered;

@property (nonatomic, weak) IBOutlet NSSlider *gen1Gain;
@property (weak) IBOutlet NSTextField *gen1GainLabel;

@property (nonatomic, weak) IBOutlet NSSlider *gen2Gain;
@property (weak) IBOutlet NSTextField *gen2GainLabel;

@property (nonatomic, weak) IBOutlet NSSlider *gen1Frequency;
@property (weak) IBOutlet NSTextField *gen1FrequencyLabel;

@property (nonatomic, weak) IBOutlet NSSlider *gen2Frequency;
@property (weak) IBOutlet NSTextField *gen2FrequencyLabel;




@end

@implementation ViewController {
    Superpowered::Generator *generator1;
    Superpowered::Generator *generator2;
    Superpowered::MonoMixer *monoMixer;
    std::atomic<bool> isUpdatingValues;
    float vol1, vol2, freq1, freq2;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    NSLog(@"Superpowered version: %u", Superpowered::Version());

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

    generator1 = new Superpowered::Generator(44100, Superpowered::Generator::Sine);
    generator2 = new Superpowered::Generator(44100, Superpowered::Generator::Sine);
    
    monoMixer = new Superpowered::MonoMixer();
    
    [self setVariables];
    

    self.superpowered = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:true enableOutput:true];
    [self.superpowered start];
}

- (void)setVariables {
        isUpdatingValues = true;
        freq1 = self.gen1Frequency.floatValue;
        self.gen1FrequencyLabel.stringValue = [NSString stringWithFormat:@"%.2f Hz", self.gen1Frequency.floatValue];
        freq2 = self.gen2Frequency.floatValue;
        self.gen2FrequencyLabel.stringValue = [NSString stringWithFormat:@"%.2f Hz", self.gen2Frequency.floatValue];
        vol1 = self.gen1Gain.floatValue;
        self.gen1GainLabel.stringValue = [NSString stringWithFormat:@"%.2f", self.gen1Gain.floatValue];
        vol2 = self.gen2Gain.floatValue;
        self.gen2GainLabel.stringValue = [NSString stringWithFormat:@"%.2f", self.gen2Gain.floatValue];
        isUpdatingValues = false;
}


- (bool)audioProcessingCallback:(float **)inputBuffers inputChannels:(unsigned int)inputChannels outputBuffers:(float **)outputBuffers outputChannels:(unsigned int)outputChannels numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
    
    float gen1OutputBuffer[numberOfFrames];
    float gen2OutputBuffer[numberOfFrames];
    
    if (!isUpdatingValues) {
        generator1->frequency = freq1;
        generator2->frequency = freq2;
        monoMixer->inputGain[0] = vol1;
        monoMixer->inputGain[1] = vol2;
    }
    
    generator1->generate(gen1OutputBuffer, numberOfFrames);
    generator2->generate(gen2OutputBuffer, numberOfFrames);
    
    monoMixer->process(
       gen1OutputBuffer,
       gen2OutputBuffer,
       NULL,
       NULL,
       outputBuffers[0],
       numberOfFrames
    );
    
    memcpy(outputBuffers[1], outputBuffers[0], sizeof(float) * numberOfFrames); // copy left mono channel to right
    return true;
}


- (IBAction)paramChanged:(id)sender {
    [self setVariables];
}


@end
