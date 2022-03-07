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
     "ExampleLicenseKey-WillExpire-OnNextUpdate"
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


- (bool)audioProcessingCallback:(float *)inputBuffer outputBuffer:(float *)outputBuffer numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
    
    // Ensure the sample rate is in sync on every audio processing callback.
    reverb->samplerate = samplerate;
    filter->samplerate = samplerate;

    // Apply the current values to the classes.
    reverb->mix = reverbMix;
    filter->frequency = filterFrequency;

    // Apply volume while copy the input buffer to the output buffer.
    Superpowered::Volume(inputBuffer, outputBuffer, previousInputGain, inputGain, numberOfFrames);
    previousInputGain = inputGain;

    // Apply reverb to output (in-place).
    reverb->process(outputBuffer, outputBuffer, numberOfFrames);

    // Apply the filter (in-place).
    filter->process(outputBuffer, outputBuffer, numberOfFrames);

    return true;
}

- (IBAction)parmChanged:(id)sender {
    [self setVariables];
}

@end
