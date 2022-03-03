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
     "ExampleLicenseKey-WillExpire-OnNextUpdate"
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

- (bool)audioProcessingCallback:(float *)inputBuffer outputBuffer:(float *)outputBuffer numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime; {
    
    // Seperate the left channel from the interleaved inputBuffer
    float monoInputBuffer[numberOfFrames];
    Superpowered::CopyMonoFromInterleaved(inputBuffer, 2, monoInputBuffer, 0, numberOfFrames);
    
    // Interleave the single channel monoInputBuffer to the interleaved outputBuffer
    Superpowered::Interleave(monoInputBuffer, monoInputBuffer, outputBuffer, numberOfFrames);
    
    // Apply volume transformation
    Superpowered::Volume(outputBuffer, outputBuffer, inputGain, previousInputGain, numberOfFrames);
    previousInputGain = inputGain;
    
    return true;
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
