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
    Superpowered::Filter *filter;
    Superpowered::Reverb *reverb;
    float inputGain, previousInputGain, reverbMix, filterFrequency;
    float inputPeak, outputPeak;
    
}

- (void)animate {
    [self.inputLevelMeter setDoubleValue: inputPeak * 10];
    [self.outputLevelMeter setDoubleValue: outputPeak * 10];
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

- (bool)audioProcessingCallback:(float *)inputBuffer outputBuffer:(float *)outputBuffer numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
    
    // Ensure the samplerate is in sync on every audio processing callback
    reverb->samplerate = samplerate;
    filter->samplerate = samplerate;

    reverb->mix = reverbMix;
    filter->frequency = filterFrequency;

    + inputPeak = (double) Superpowered::Peak(inputBuffer, numberOfFrames);

    Superpowered::Volume(inputBuffer, outputBuffer, previousInputGain, inputGain, numberOfFrames);
    previousInputGain = inputGain;

    // Apply reverb
    reverb->process(outputBuffer, outputBuffer, numberOfFrames);

    // Apply the filter
    filter->process(outputBuffer, outputBuffer, numberOfFrames);

    + outputPeak = (double) Superpowered::Peak(outputBuffer, numberOfFrames);

    return true;
}

- (IBAction)parmChanged:(id)sender {
    [self setVariables];
}

@end

