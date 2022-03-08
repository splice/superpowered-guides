#import "ViewController.h"
#import "Superpowered.h"
#import "SuperpoweredSimple.h"
#import "SuperpoweredOSXAudioIO.h"
#import "SuperpoweredFilter.h"
#import "SuperpoweredReverb.h"

@interface ViewController ()
@property (weak) IBOutlet NSSlider *inputGainSlider;
@property (weak) IBOutlet NSSlider *reverbMixSlider;
@property (weak) IBOutlet NSSlider *filterFrequencySlider;
@end

@implementation ViewController {
    SuperpoweredOSXAudioIO *audioIO;
    Superpowered::Filter *filter;
    Superpowered::Reverb *reverb;
    float previousInputGain;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    Superpowered::Initialize("ExampleLicenseKey-WillExpire-OnNextUpdate");
    NSLog(@"Superpowered version: %u", Superpowered::Version());

    reverb = new Superpowered::Reverb(48000, 48000);
    filter = new Superpowered::Filter(Superpowered::Filter::FilterType::Resonant_Lowpass, 48000);

    reverb->enabled = true;
    filter->enabled = true;

    [self paramChanged:nil];
    previousInputGain = 0;

    audioIO = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:true enableOutput:true];
    [audioIO start];
}

- (void)dealloc {
    // Stops and deallocates audioIO (because ARC is enabled).
    // audioProcessingCallback is not called after this.
    audioIO = nil;
    // Now it's safe to delete the rest.
    delete reverb;
    delete filter;
}

- (IBAction)paramChanged:(id)sender {
    // Set the current values of the effects.
    // This function is called on the main thread and can concurrently happen with audioProcessingCallback, but the Superpowered effects are prepared to handle concurrency.
    // Values are automatically smoothed as well, so no audio artifacts can be heard.
    filter->frequency = self.filterFrequencySlider.floatValue;
    reverb->mix = self.reverbMixSlider.floatValue;
}

- (bool)audioProcessingCallback:(float *)inputBuffer outputBuffer:(float *)outputBuffer numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
    // Ensure the sample rate is in sync on every audio processing callback.
    reverb->samplerate = samplerate;
    filter->samplerate = samplerate;

    // Apply volume while copy the input buffer to the output buffer.
    // Gain is smoothed, starting from "previousInputGain" to "inputGain".
    float inputGain = self.inputGainSlider.floatValue;
    Superpowered::Volume(inputBuffer, outputBuffer, previousInputGain, inputGain, numberOfFrames);
    previousInputGain = inputGain; // Save the gain for the next round.

    // Apply reverb to output (in-place).
    reverb->process(outputBuffer, outputBuffer, numberOfFrames);

    // Apply the filter (in-place).
    filter->process(outputBuffer, outputBuffer, numberOfFrames);

    return true;
}

@end
