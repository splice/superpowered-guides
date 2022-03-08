#import "ViewController.h"
#import "Superpowered.h"
#import "SuperpoweredSimple.h"
#import "SuperpoweredOSXAudioIO.h"
#import "SuperpoweredAdvancedAudioPlayer.h"

@interface ViewController ()
@property (nonatomic, strong) SuperpoweredOSXAudioIO *superpowered;
@property (weak) IBOutlet NSSlider *localPlaybackRate;
@property (weak) IBOutlet NSSlider *localPlaybackPitch;
@property (weak) IBOutlet NSSlider *localGain;
@property (weak) IBOutlet NSButton *playLocalButton;
@property (weak) IBOutlet NSSlider *remoteVolume;
@property (weak) IBOutlet NSButton *playRemoteButton;
@end

@implementation ViewController {
    SuperpoweredOSXAudioIO *audioIO;
    Superpowered::AdvancedAudioPlayer *playerA, *playerB;
    float localGainValue, localPlaybackRateValue, localPlaybackPitchValue, remoteGainValue;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    Superpowered::Initialize("ExampleLicenseKey-WillExpire-OnNextUpdate");
    NSLog(@"Superpowered version: %u", Superpowered::Version());

    // Let Superpowered know where it can store the temporary files used for buffering HLS.
    Superpowered::AdvancedAudioPlayer::setTempFolder([NSTemporaryDirectory() fileSystemRepresentation]);

    // Create two instances of the AdvancedAudioPlayer class, which we'll use to play our local and HLS stream.
    playerA = new Superpowered::AdvancedAudioPlayer(48000, 0);
    playerB = new Superpowered::AdvancedAudioPlayer(48000, 0);

    // Open a local file.
    playerA->open([[[NSBundle mainBundle] pathForResource:@"lycka" ofType:@"mp3"] fileSystemRepresentation]);

    // Open a remote HLS stream.
    playerB->openHLS("http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/sl.m3u8");
    playerB->HLSBufferingSeconds = 20;

    [self updateParams:nil];

    audioIO = [[SuperpoweredOSXAudioIO alloc] initWithDelegate:(id<SuperpoweredOSXAudioIODelegate>)self preferredBufferSizeMs:12 numberOfChannels:2 enableInput:true enableOutput:true];
    [audioIO start];
}

- (void)dealloc {
    // Stops and deallocates audioIO (because ARC is enabled).
    // audioProcessingCallback is not called after this.
    audioIO = nil;
    // Now it's safe to delete the rest.
    delete playerA;
    delete playerB;
}

- (IBAction)playLocalAudio:(id)sender {
    playerA->togglePlayback(); // play/pause
}

- (IBAction)playRemote:(id)sender {
    playerB->togglePlayback(); // play/pause
}

- (IBAction)updateParams:(id)sender {
    // Set some player properties.
    // This function is called on the main thread and can concurrently happen with audioProcessingCallback, but the Superpowered AdvancedAudioPlayer is prepared to handle concurrency.
    // Values are automatically smoothed as well, so no audio artifacts can be heard.
    playerA->playbackRate = self.localPlaybackRate.floatValue;
    playerA->pitchShiftCents = self.localPlaybackPitch.floatValue;

    // Save the volume values, because those are not player properties.
    localGainValue = self.localGain.floatValue;
    remoteGainValue = self.remoteVolume.floatValue;
}

- (void)enableUIForPlayerA {
    self.playLocalButton.enabled = true;
    self.localPlaybackRate.enabled = true;
    self.localPlaybackPitch.enabled = true;
    self.localGain.enabled = true;
}

- (void)enableUIForPlayerB {
    self.playRemoteButton.enabled = true;
    self.remoteVolume.enabled = true;
}

- (bool)audioProcessingCallback:(float *)inputBuffer outputBuffer:(float *)outputBuffer numberOfFrames:(unsigned int)numberOfFrames samplerate:(unsigned int)samplerate hostTime:(unsigned long long int)hostTime {
    // Ensure the samplerate is in sync on every audio processing callback.
    playerA->outputSamplerate = samplerate;
    playerB->outputSamplerate = samplerate;

    // Check player statuses. We're only interested in the Opened event in this example.
    if (playerA->getLatestEvent() == Superpowered::AdvancedAudioPlayer::PlayerEvent_Opened) {
        // Enable the UI elements for player A. Apple requires UI updates on the main thread.
        [self performSelectorOnMainThread:@selector(enableUIForPlayerA) withObject:nil waitUntilDone:NO];
    };

    if (playerB->getLatestEvent() == Superpowered::AdvancedAudioPlayer::PlayerEvent_Opened) {
        // Enable the UI elements for player B. Apple requires UI updates on the main thread.
        [self performSelectorOnMainThread:@selector(enableUIForPlayerB) withObject:nil waitUntilDone:NO];
        // Fast forward in the stream a bit.
        playerB->setPosition(6000, true, false);
    };

    // Store the output of player A into outputBuffer.
    bool silence = !playerA->processStereo(outputBuffer, false, numberOfFrames, localGainValue);

    // If silence, then player B may overwrite the contents of outputBuffer.
    // If no silence, then player B may mix its output with the contents of outputBuffer.
    if (playerB->processStereo(outputBuffer, !silence, numberOfFrames, remoteGainValue)) silence = false;

    return !silence;
}

@end
