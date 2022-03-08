#import "ViewController.h"
#import "Superpowered.h"
#import "SuperpoweredSimple.h"
#import "SuperpoweredOSXAudioIO.h"
#import "SuperpoweredGenerator.h"
#import "CustomButton.h"

@interface ViewController ()
@property (weak) IBOutlet CustomButton *buttonA;
@property (weak) IBOutlet CustomButton *buttonB;
@property (weak) IBOutlet CustomButton *buttonC;
@property (weak) IBOutlet CustomButton *buttonD;
@end

@implementation ViewController {
    SuperpoweredOSXAudioIO *audioIO;
    Superpowered::Generator *generator;
    float genVolume, genPreviousVolume;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    Superpowered::Initialize("ExampleLicenseKey-WillExpire-OnNextUpdate");
    NSLog(@"Superpowered version: %u", Superpowered::Version());

    generator = new Superpowered::Generator(48000, Superpowered::Generator::Sine);

    genVolume = 0;
    genPreviousVolume = 0;
    [self bindButtonActions];

    audioIO = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:true enableOutput:true];
    [audioIO start];
}

- (void)dealloc {
    // Stops and deallocates audioIO (because ARC is enabled).
    // audioProcessingCallback is not called after this.
    audioIO = nil;
    // Now it's safe to delete the generator.
    delete generator;
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

-(void)playNote:(float)frequency {
    generator->frequency = frequency;
    genVolume = 0.5;
    NSLog(@"mouse down: %f", frequency);
}

-(void)stopNote {
    genVolume = 0;
    NSLog(@"mouse up");
}

- (bool)audioProcessingCallback:(float *)inputBuffer outputBuffer:(float *)outputBuffer numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
    // Ensure the samplerate is in sync on every audio processing callback.
    generator->samplerate = samplerate;

    // Generate the tone (full volume).
    float monoBuffer[numberOfFrames];
    generator->generate(monoBuffer, numberOfFrames);

    // Copy the mono buffer into the interleaved stereo output.
    Superpowered::Interleave(
        monoBuffer, // left side
        monoBuffer, // right side
        outputBuffer,
        numberOfFrames
    );

    // Apply volume. genPreviousVolume is the start of the volume ramp, and genVolume is the destination of the ramp.
    // The ramp takes place over the length of the buffer (numberOfFrames).
    Superpowered::Volume(
        outputBuffer,
        outputBuffer,
        genPreviousVolume,
        genVolume,
        numberOfFrames
    );
    // Save the latest volume value which is used in the next process loop call.
    genPreviousVolume = genVolume;

    return true;
}

@end
