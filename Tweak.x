#import "../YTVideoOverlay/Header.h"
#import "../YTVideoOverlay/Init.x"
#import "../YouTubeHeader/YTColor.h"
#import "../YouTubeHeader/YTMainAppVideoPlayerOverlayViewController.h"
#import "../YouTubeHeader/YTSingleVideoController.h"
#import "../YouTubeHeader/YTTypeStyle.h"
#import "../YouTubeHeader/MLFormat.h"

#define TweakKey @"YouQuality"

@interface YTMainAppControlsOverlayView (YouQuality)
@property (retain, nonatomic) YTQTMButton *qualityButton;
- (void)didPressYouQuality:(id)arg;
- (void)updateYouQualityButton:(id)arg;
@end

@interface YTInlinePlayerBarContainerView (YouQuality)
@property (retain, nonatomic) YTQTMButton *qualityButton;
- (void)didPressYouQuality:(id)arg;
- (void)updateYouQualityButton:(id)arg;
@end

NSString *YouQualityUpdateNotification = @"YouQualityUpdateNotification";
NSString *currentQualityLabel = @"na";

NSBundle *YouQualityBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:TweakKey ofType:@"bundle"];
        if (tweakBundlePath)
            bundle = [NSBundle bundleWithPath:tweakBundlePath];
        else
            bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:ROOT_PATH_NS(@"/Library/Application Support/%@.bundle"), TweakKey]];
    });
    return bundle;
}

static UIImage *qualityImage(NSString *qualityLabel) {
    return [%c(QTMIcon) tintImage:[UIImage imageNamed:qualityLabel inBundle:YouQualityBundle() compatibleWithTraitCollection:nil] color:[%c(YTColor) white1]];
}

static void configureButtonStyle(YTQTMButton *button) {
    [button setTitleColor:[%c(YTColor) white1] forState:0];
    YTDefaultTypeStyle *defaultTypeStyle = [%c(YTTypeStyle) defaultTypeStyle];
    UIFont *font = [defaultTypeStyle respondsToSelector:@selector(ytSansFontOfSize:weight:)]
        ? [defaultTypeStyle ytSansFontOfSize:10 weight:UIFontWeightSemibold]
        : [defaultTypeStyle fontOfSize:10 weight:UIFontWeightSemibold];
    button.titleLabel.font = font;
    button.titleLabel.numberOfLines = 2;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
}

%group Video

NSString *getCompactQualityLabel(MLFormat *format) {
    NSString *qualityLabel = [format qualityLabel];
    BOOL shouldShowFPS = [format FPS] > 30;
    if ([qualityLabel hasPrefix:@"2160p"])
        qualityLabel = [qualityLabel stringByReplacingOccurrencesOfString:@"2160p" withString:shouldShowFPS ? @"4K\n" : @"4K"];
    else if ([qualityLabel hasPrefix:@"1440p"])
        qualityLabel = [qualityLabel stringByReplacingOccurrencesOfString:@"1440p" withString:shouldShowFPS ? @"2K\n" : @"2K"];
    else if ([qualityLabel hasPrefix:@"1080p"])
        qualityLabel = [qualityLabel stringByReplacingOccurrencesOfString:@"1080p" withString:shouldShowFPS ? @"HD\n" : @"HD"];
    else if (shouldShowFPS)
        qualityLabel = [qualityLabel stringByReplacingOccurrencesOfString:@"p" withString:@"p\n"];
    return qualityLabel;
}

%hook YTVideoQualitySwitchOriginalController

- (void)singleVideo:(id)singleVideo didSelectVideoFormat:(MLFormat *)format {
    currentQualityLabel = getCompactQualityLabel(format);
    [[NSNotificationCenter defaultCenter] postNotificationName:YouQualityUpdateNotification object:nil];
    %orig;
}

%end

%hook YTVideoQualitySwitchRedesignedController

- (void)singleVideo:(id)singleVideo didSelectVideoFormat:(MLFormat *)format {
    currentQualityLabel = getCompactQualityLabel(format);
    [[NSNotificationCenter defaultCenter] postNotificationName:YouQualityUpdateNotification object:nil];
    %orig;
}

%end

%end

%group Top

%hook YTMainAppControlsOverlayView

%property (retain, nonatomic) YTQTMButton *qualityButton;

- (id)initWithDelegate:(id)delegate {
    self = %orig;
    self.qualityButton = [self createTextButton:TweakKey accessibilityLabel:@"Quality" selector:@selector(didPressYouQuality:)];
    configureButtonStyle(self.qualityButton);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateYouQualityButton:) name:YouQualityUpdateNotification object:nil];
    return self;
}

- (id)initWithDelegate:(id)delegate autoplaySwitchEnabled:(BOOL)autoplaySwitchEnabled {
    self = %orig;
    self.qualityButton = [self createTextButton:TweakKey accessibilityLabel:@"Quality" selector:@selector(didPressYouQuality:)];
    configureButtonStyle(self.qualityButton);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateYouQualityButton:) name:YouQualityUpdateNotification object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}

- (YTQTMButton *)button:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? self.qualityButton : %orig;
}

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? qualityImage(currentQualityLabel) : %orig;
}

%new(v@:@)
- (void)updateYouQualityButton:(id)arg {
    [self.qualityButton setTitle:currentQualityLabel forState:0];
}

%new(v@:@)
- (void)didPressYouQuality:(id)arg {
    YTMainAppVideoPlayerOverlayViewController *c = [self valueForKey:@"_eventsDelegate"];
    [c didPressVideoQuality:arg];
    [self updateYouQualityButton:nil];
}

%end

%end

%group Bottom

%hook YTInlinePlayerBarContainerView

%property (retain, nonatomic) YTQTMButton *qualityButton;

- (id)init {
    self = %orig;
    self.qualityButton = [self createTextButton:TweakKey accessibilityLabel:@"Quality" selector:@selector(didPressYouQuality:)];
    configureButtonStyle(self.qualityButton);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateYouQualityButton:) name:YouQualityUpdateNotification object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}

- (YTQTMButton *)button:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? self.qualityButton : %orig;
}

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? qualityImage(currentQualityLabel) : %orig;
}

%new(v@:@)
- (void)updateYouQualityButton:(id)arg {
    [self.qualityButton setTitle:currentQualityLabel forState:0];
}

%new(v@:@)
- (void)didPressYouQuality:(id)arg {
    YTMainAppVideoPlayerOverlayViewController *c = [self.delegate valueForKey:@"_delegate"];
    [c didPressVideoQuality:arg];
    [self updateYouQualityButton:nil];
}

%end

%end

%ctor {
    initYTVideoOverlay(TweakKey);
    %init(Video);
    %init(Top);
    %init(Bottom);
}
