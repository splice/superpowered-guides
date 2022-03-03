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

@property (nonatomic, weak) IBOutlet NSSlider *gen1Gain;
@property (weak) IBOutlet NSTextField *gen1GainLabel;

@property (nonatomic, weak) IBOutlet NSSlider *gen2Gain;
@property (weak) IBOutlet NSTextField *gen2GainLabel;

@property (nonatomic, weak) IBOutlet NSSlider *gen1Frequency;
@property (weak) IBOutlet NSTextField *gen1FrequencyLabel;

@property (weak) IBOutlet NSSlider *gen2Frequency;
@property (weak) IBOutlet NSTextField *gen2FrequencyLabel;




@end

@implementation ViewController {
    Superpowered::Generator *generator1;
    Superpowered::Generator *generator2;
    Superpowered::MonoMixer *monoMixer;
    float vol1, vol2, freq1, freq2;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    NSLog(@"Superpowered version: %u", Superpowered::Version());

    Superpowered::Initialize(
     "ExampleLicenseKey-WillExpire-OnNextUpdate"
    );

    generator1 = new Superpowered::Generator(44100, Superpowered::Generator::Sine);
    generator2 = new Superpowered::Generator(44100, Superpowered::Generator::Sine);
    
    monoMixer = new Superpowered::MonoMixer();
    
    [self setVariables];
    

    self.superpowered = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:true enableOutput:true];
    [self.superpowered start];
}

- (void)setVariables {
        freq1 = self.gen1Frequency.floatValue;
        self.gen1FrequencyLabel.stringValue = [NSString stringWithFormat:@"%.2f Hz", self.gen1Frequency.floatValue];
        freq2 = self.gen2Frequency.floatValue;
        self.gen2FrequencyLabel.stringValue = [NSString stringWithFormat:@"%.2f Hz", self.gen2Frequency.floatValue];
        vol1 = self.gen1Gain.floatValue;
        self.gen1GainLabel.stringValue = [NSString stringWithFormat:@"%.2f", self.gen1Gain.floatValue];
        vol2 = self.gen2Gain.floatValue;
        self.gen2GainLabel.stringValue = [NSString stringWithFormat:@"%.2f", self.gen2Gain.floatValue];
}

- (bool)audioProcessingCallback:(float *)inputBuffer outputBuffer:(float *)outputBuffer numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime; {
    
    // Ensure the samplerate is in sync on every audio processing callback
    generator1->samplerate = samplerate;
    generator2->samplerate = samplerate;

    // Render the output buffers

    float gen1OutputBuffer[numberOfFrames];
    float gen2OutputBuffer[numberOfFrames];
    
    generator1->frequency = freq1;
    generator2->frequency = freq2;
    monoMixer->inputGain[0] = vol1;
    monoMixer->inputGain[1] = vol2;
    
    generator1->generate(gen1OutputBuffer, numberOfFrames);
    generator2->generate(gen2OutputBuffer, numberOfFrames);
    
    // create mono buffer for mono mixer output
    float monoBuffer[numberOfFrames];
    
    monoMixer->process(
       gen1OutputBuffer,
       gen2OutputBuffer,
       NULL,
       NULL,
       monoBuffer,
       numberOfFrames
    );
    
    // Interleave mono buffer to stereo output
    Superpowered::Interleave(monoBuffer, monoBuffer, outputBuffer, numberOfFrames);

    return true;
}

- (IBAction)paramChanged:(id)sender {
    [self setVariables];
}


@end
