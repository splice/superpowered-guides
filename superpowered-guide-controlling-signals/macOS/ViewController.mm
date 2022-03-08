#import "ViewController.h"
#import "Superpowered.h"
#import "SuperpoweredSimple.h"
#import "SuperpoweredOSXAudioIO.h"
#import "SuperpoweredGenerator.h"
#import "SuperpoweredMixer.h"

@interface ViewController ()
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
    SuperpoweredOSXAudioIO *audioIO;
    Superpowered::Generator *generator1;
    Superpowered::Generator *generator2;
    Superpowered::MonoMixer *monoMixer;
    float vol1, vol2;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    Superpowered::Initialize("ExampleLicenseKey-WillExpire-OnNextUpdate");
    NSLog(@"Superpowered version: %u", Superpowered::Version());

    // Create the Generators and a MonoMixer to sum signals.
    generator1 = new Superpowered::Generator(44100, Superpowered::Generator::Sine);
    generator2 = new Superpowered::Generator(44100, Superpowered::Generator::Sine);
    monoMixer = new Superpowered::MonoMixer();

    [self paramChanged:nil];

    audioIO = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:true enableOutput:true];
    [audioIO start];
}

- (void)dealloc {
    // Stops and deallocates audioIO (because ARC is enabled).
    // audioProcessingCallback is not called after this.
    audioIO = nil;
    // Now it's safe to delete the rest.
    delete generator1;
    delete generator2;
    delete monoMixer;
}

- (IBAction)paramChanged:(id)sender {
    // Set the generator frequencies.
    // This function is called on the main thread and can concurrently happen with audioProcessingCallback, but the Superpowered Generator is prepared to handle concurrency.
    // Values are automatically smoothed as well, so no audio artifacts can be heard.
    generator1->frequency = self.gen1Frequency.floatValue;
    generator2->frequency = self.gen2Frequency.floatValue;

    // The mixer doesn't have concurrency capabilites, so let's save the volume values.
    vol1 = self.gen1Gain.floatValue;
    vol2 = self.gen2Gain.floatValue;

    // Update the user interface.
    self.gen1FrequencyLabel.stringValue = [NSString stringWithFormat:@"%.2f Hz", self.gen1Frequency.floatValue];
    self.gen2FrequencyLabel.stringValue = [NSString stringWithFormat:@"%.2f Hz", self.gen2Frequency.floatValue];
    self.gen1GainLabel.stringValue = [NSString stringWithFormat:@"%.2f", self.gen1Gain.floatValue];
    self.gen2GainLabel.stringValue = [NSString stringWithFormat:@"%.2f", self.gen2Gain.floatValue];
}

- (bool)audioProcessingCallback:(float *)inputBuffer outputBuffer:(float *)outputBuffer numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
    // Ensure the samplerate is in sync on every audio processing callback.
    generator1->samplerate = samplerate;
    generator2->samplerate = samplerate;

    // Generate the tones into two buffers.
    float gen1OutputBuffer[numberOfFrames];
    float gen2OutputBuffer[numberOfFrames];
    generator1->generate(gen1OutputBuffer, numberOfFrames);
    generator2->generate(gen2OutputBuffer, numberOfFrames);

    // Update the mixer gains.
    monoMixer->inputGain[0] = vol1;
    monoMixer->inputGain[1] = vol2;

    // Mix the two tones into another buffer.
    float monoBuffer[numberOfFrames];
    monoMixer->process(
       gen1OutputBuffer, // input 1
       gen2OutputBuffer, // input 2
       NULL,             // input 3 (empty)
       NULL,             // input 4 (empty)
       monoBuffer,       // output
       numberOfFrames
    );

    // Copy the mono buffer into the interleaved stereo output.
    Superpowered::Interleave(
        monoBuffer, // left side
        monoBuffer, // right side
        outputBuffer,
        numberOfFrames
    );
    return true;
}

@end
