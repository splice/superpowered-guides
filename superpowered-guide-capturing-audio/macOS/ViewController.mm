#import "ViewController.h"
#import "Superpowered.h"
#import "SuperpoweredSimple.h"
#import "SuperpoweredOSXAudioIO.h"

@interface ViewController ()
@property (weak) IBOutlet NSSlider *inputGainSlider;
@end

@implementation ViewController {
    SuperpoweredOSXAudioIO *audioIO;
    float previousInputGain;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    Superpowered::Initialize("ExampleLicenseKey-WillExpire-OnNextUpdate");
    NSLog(@"Superpowered version: %u", Superpowered::Version());

    previousInputGain = 0;

    audioIO = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:true enableOutput:true];
    [audioIO start];
}

- (void)dealloc {
    // Stops and deallocates audioIO (because ARC is enabled).
    // audioProcessingCallback is not called after this.
    audioIO = nil;
}

- (IBAction)paramChanged:(id)sender {

}

- (bool)audioProcessingCallback:(float *)inputBuffer outputBuffer:(float *)outputBuffer numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime; {
    // Apply volume while copy the input buffer to the output buffer.
    // Gain is smoothed, starting from "previousInputGain" to "inputGain".
    float inputGain = self.inputGainSlider.floatValue;
    Superpowered::Volume(inputBuffer, outputBuffer, previousInputGain, inputGain, numberOfFrames);
    previousInputGain = inputGain; // Save the gain for the next round.
    return true;
}

@end
