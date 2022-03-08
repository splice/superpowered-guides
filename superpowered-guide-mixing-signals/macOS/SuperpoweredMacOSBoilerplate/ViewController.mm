#import "ViewController.h"
#import "Superpowered.h"
#import "SuperpoweredSimple.h"
#import "SuperpoweredOSXAudioIO.h"
#import "SuperpoweredGenerator.h"
#import "SuperpoweredMixer.h"

@interface ViewController ()
@end

@implementation ViewController {
    SuperpoweredOSXAudioIO *audioIO;
    Superpowered::Generator *generator1;
    Superpowered::Generator *generator2;
    Superpowered::MonoMixer *monoMixer;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    Superpowered::Initialize("ExampleLicenseKey-WillExpire-OnNextUpdate");
    NSLog(@"Superpowered version: %u", Superpowered::Version());

    // Create the Generators and a MonoMixer to sum signals.
    generator1 = new Superpowered::Generator(48000, Superpowered::Generator::Sine);
    generator2 = new Superpowered::Generator(48000, Superpowered::Generator::Sine);
    monoMixer = new Superpowered::MonoMixer();

    // Fixed gain values for the mixer channels.
    monoMixer->inputGain[0] = 0.5f;
    monoMixer->inputGain[1] = 0.5f;

    // Fixed frequencies for the two generators.
    generator1->frequency = 440;
    generator2->frequency = 660;

    // Start audio I/O.
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

- (bool)audioProcessingCallback:(float *)inputBuffer outputBuffer:(float *)outputBuffer numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
    // Ensure the samplerate is in sync on every audio processing callback.
    generator1->samplerate = samplerate;
    generator2->samplerate = samplerate;

    // Generate the tones into two buffers.
    float gen1OutputBuffer[numberOfFrames];
    float gen2OutputBuffer[numberOfFrames];
    generator1->generate(gen1OutputBuffer, numberOfFrames);
    generator2->generate(gen2OutputBuffer, numberOfFrames);

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
