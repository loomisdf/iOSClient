//
//  NpcScriptElementView.m
//  ARIS
//
//  Created by Phil Dougherty on 8/5/13.
//
//

#import "NpcScriptElementView.h"
#import <AVFoundation/AVFoundation.h>
#import "ScriptElement.h"
#import "ARISMediaView.h"
#import "ARISWebView.h"
#import "ARISAppDelegate.h"
#import "ARISMoviePlayerViewController.h"
#import "ARISCollapseView.h"
#import "StateControllerProtocol.h"
#import "AppModel.h"
#import "UIColor+ARISColors.h"

@interface NpcScriptElementView() <ARISMediaViewDelegate, ARISCollapseViewDelegate, StateControllerProtocol, ARISWebViewDelegate, UIWebViewDelegate, UIWebViewDelegate, UIScrollViewDelegate>
{
    ScriptElement *scriptElement;
    
    UIScrollView *mediaSection;
    ARISMediaView *mediaView;
    ARISCollapseView *textSection;
    ARISWebView *textWebView;
    
    NSString *defaultTitle;
    Media *defaultMedia;
    UIImage *defaultImage;
    
    id<NPcScriptElementViewDelegate> __unsafe_unretained delegate;
}

@property (nonatomic, strong) ScriptElement *scriptElement;

@property (nonatomic, strong) UIScrollView *mediaSection;
@property (nonatomic, strong) ARISMediaView *mediaView;
@property (nonatomic, strong) ARISCollapseView *textSection;
@property (nonatomic, strong) ARISWebView *textWebView;

@property (nonatomic, strong) NSString *defaultTitle;
@property (nonatomic, strong) Media *defaultMedia;
@property (nonatomic, strong) UIImage *defaultImage;

@end

@implementation NpcScriptElementView

@synthesize scriptElement;

@synthesize mediaSection;
@synthesize mediaView;
@synthesize textSection;
@synthesize textWebView;

@synthesize defaultTitle;
@synthesize defaultMedia;
@synthesize defaultImage;

- (void) initialize
{
    self.backgroundColor = [UIColor clearColor];
    self.mediaSection = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.mediaSection.contentInset = UIEdgeInsetsMake(64,0,0,0);
    self.mediaSection.contentSize = self.bounds.size;
    self.mediaSection.backgroundColor = [UIColor clearColor];
    self.mediaSection.opaque = NO;
    [self.mediaSection addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(passTapToTextSection:)]];
    
    self.textWebView = [[ARISWebView alloc] initWithFrame:CGRectMake(10, 10, self.bounds.size.width-20, 10) delegate:self];
    self.textWebView.opaque = NO;
    self.textWebView.backgroundColor = [UIColor clearColor];
    [self.textWebView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(passTapToTextSection:)]];
    
    self.textSection = [[ARISCollapseView alloc] initWithView:self.textWebView frame:CGRectMake(0, self.bounds.size.height-128, self.bounds.size.width, 128) open:YES showHandle:YES draggable:YES tappable:YES delegate:self];
    
    [self addSubview:self.mediaSection];
    [self.mediaSection addSubview:self.mediaView];
    [self addSubview:self.textSection];
}

- (id) initWithFrame:(CGRect)f media:(Media *)m title:(NSString *)t delegate:(id)d
{
    if(self = [super initWithFrame:f])
    {
        self.defaultTitle = t;
        self.defaultMedia = m;
        self.mediaView = [[ARISMediaView alloc] initWithFrame:self.bounds media:m mode:ARISMediaDisplayModeTopAlignAspectFitWidth delegate:self];
        [self initialize];
        self.mediaView.backgroundColor = [UIColor clearColor];
        self.mediaSection.opaque = NO;

        delegate = d;
    }
    return self;
}

- (id) initWithFrame:(CGRect)f image:(UIImage *)i title:(NSString *)t delegate:(id)d;
{
    if(self = [super initWithFrame:f])
    {
        self.defaultTitle = t;
        self.defaultImage = i;
        self.mediaView = [[ARISMediaView alloc] initWithFrame:self.bounds image:i mode:ARISMediaDisplayModeTopAlignAspectFitWidth delegate:self];
        self.mediaView.backgroundColor = [UIColor clearColor];
        self.mediaSection.opaque = NO;
        [self initialize];
        
        delegate = d;
    }
    return self;
}

- (void) passTapToTextSection:(UITapGestureRecognizer *)r
{
    [self.textSection handleTapped:r];
}

- (void) loadScriptElement:(ScriptElement *)s
{
    self.scriptElement = s;
    
    if(self.scriptElement.vibrate) [((ARISAppDelegate *)[[UIApplication sharedApplication] delegate]) vibrate];
    if(self.scriptElement.title) [delegate scriptElementViewRequestsTitle:self.scriptElement.title];
    else                         [delegate scriptElementViewRequestsTitle:self.defaultTitle];
    
    if(self.scriptElement.mediaId != 0)
    {
        Media *media = [[AppModel sharedAppModel] mediaForMediaId:self.scriptElement.mediaId ofType:@"PHOTO"];//if it can't find a media, assume it is a photo
        [self.mediaView refreshWithFrame:self.mediaView.frame media:media mode:ARISMediaDisplayModeTopAlignAspectFitWidth delegate:self];
        if([media.type isEqualToString:@"VIDEO"]) [self playAudioOrVideoFromMedia:media andHidden:NO];
        if([media.type isEqualToString:@"AUDIO"]) [self playAudioOrVideoFromMedia:media andHidden:YES];
    }
    else if(self.defaultImage)
        [self.mediaView refreshWithFrame:self.mediaView.frame image:self.defaultImage mode:ARISMediaDisplayModeTopAlignAspectFitWidth delegate:self];
    else if(self.defaultMedia)
        [self.mediaView refreshWithFrame:self.mediaView.frame media:self.defaultMedia mode:ARISMediaDisplayModeTopAlignAspectFitWidth delegate:self];
    
    //Try resetting the text view height to 0 each time for proper content height calculation
    CGRect wvFrame = [self.textWebView frame];
    [self.textWebView setFrame:CGRectMake(wvFrame.origin.x, wvFrame.origin.y, wvFrame.size.width, 10)];
    //Load content
    [self.textWebView loadHTMLString:[NSString stringWithFormat:[UIColor ARISHtmlTemplate], self.scriptElement.text] baseURL:nil];
    
    //PHIL
    /*
    self.mediaSection.frame = CGRectMake(0,0,self.mediaView.frame.size.width,self.mediaView.frame.size.height);
    CGRect oldImageFrame = self.mediaSection.frame;
    CGRect newImageFrame = self.scriptElement.imageRect;
    
    CGRect zoomContainerRect = CGRectMake((int)(-1*newImageFrame.origin.x*oldImageFrame.size.width/newImageFrame.size.width),
                                          (int)(-1*newImageFrame.origin.y*oldImageFrame.size.height/newImageFrame.size.height),
                                          (int)(oldImageFrame.size.width*oldImageFrame.size.width/newImageFrame.size.width),
                                          (int)(oldImageFrame.size.height*oldImageFrame.size.height/newImageFrame.size.height));

    [UIView transitionWithView:self.mediaSection.superview duration:self.scriptElement.zoomTime options:UIViewAnimationCurveLinear|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionLayoutSubviews animations:^
    {
        self.mediaView.frame  = zoomContainerRect;

        //However, apple gets mad when you try to animate a view and subview simultaneously, so instead we overanimate the subview to compensate and comment out the superview's animation
        self.mediaView.frame = CGRectMake(self.mediaSection.frame.origin.x+self.mediaView.frame.origin.x,self.mediaSection.frame.origin.y+self.mediaView.frame.origin.y,self.mediaView.frame.size.width,self.mediaView.frame.size.height);
    }
    completion:nil];
     */
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void) ARISWebViewRequestsDismissal:(ARISWebView *)awv
{
    
}

- (void) ARISWebViewRequestsRefresh:(ARISWebView *)awv
{
    
}

- (void) fadeWithCallback:(SEL)s
{
    [UIView beginAnimations:@"dialog" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationDelegate:delegate];
    [UIView setAnimationDidStopSelector:s];
    self.textWebView.alpha  = 0;
    [UIView commitAnimations];
    
    //[ARISMoviePlayer.moviePlayer.view removeFromSuperview];
    //[self.npcVideoView removeFromSuperview];
    //[ARISMoviePlayer.moviePlayer stop];
    
    //if(audioPlayer.isPlaying) [audioPlayer stop];
    
    //[[AVAudioSession sharedInstance] setActive:NO error:nil];
    //audioPlayer = nil;
}

- (void) ARISMediaViewUpdated:(ARISMediaView *)amv
{
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
	//Size the webView
	CGRect wvFrame = [webView frame];
    CGFloat wvHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"] floatValue];
	webView.frame = CGRectMake(wvFrame.origin.x, wvFrame.origin.y, wvFrame.size.width, wvHeight);
	[[[webView subviews] lastObject] setScrollEnabled:NO]; //Disable scrolling in webview
    
    [self.textSection setOpenFrameHeight:wvHeight+54];
	
    //Fade in the WebView
    [UIView beginAnimations:@"dialog" context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView setAnimationDuration:0.25];
    self.textWebView.alpha = 1.0;
    [UIView commitAnimations];
}

- (void) playAudioOrVideoFromMedia:(Media*)media andHidden:(BOOL)hidden
{
    if(media.image != nil && [media.type isEqualToString:@"AUDIO"])
    {
        NSLog(@"NpcViewController: Playing through AVAudioPlayer");
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];	
        [[AVAudioSession sharedInstance] setActive: YES error: nil];
        NSError* err;
        AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithData: media.image error:&err];
        //[audioPlayer setDelegate:self];
        
        if(err) NSLog(@"NpcViewController: Playing Audio: Failed with reason: %@", [err localizedDescription]);
        else [audioPlayer play];
    }
    else
    {
        NSLog(@"NpcViewController: Playing through MPMoviePlayerController");
        ARISMoviePlayerViewController *ARISMoviePlayer = [[ARISMoviePlayerViewController alloc] init];
        ARISMoviePlayer.moviePlayer.view.hidden = hidden; 
        ARISMoviePlayer.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
        [ARISMoviePlayer.moviePlayer setContentURL: [NSURL URLWithString:media.url]];
        [ARISMoviePlayer.moviePlayer setControlStyle:MPMovieControlStyleNone];
        [ARISMoviePlayer.moviePlayer setFullscreen:NO];
        [ARISMoviePlayer.moviePlayer prepareToPlay];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(MPMoviePlayerLoadStateDidChangeNotification: ) name:MPMoviePlayerLoadStateDidChangeNotification object:ARISMoviePlayer.moviePlayer];
        if(!hidden)
        {
            ARISMoviePlayer.view.frame = self.mediaView.frame;
            //self.npcVideoView = (UIScrollView *)ARISMoviePlayer.view;
            //self.npcVideoView.hidden = NO;
            //[self.npcView insertSubview:npcVideoView atIndex: 1];
            //self.npcImageView.hidden = YES;
        }
    }
}

- (void) MPMoviePlayerLoadStateDidChangeNotification:(NSNotification *)notif
{
    //if(ARISMoviePlayer.moviePlayer.loadState & MPMovieLoadStateStalled)
        //[ARISMoviePlayer.moviePlayer pause];
    //else if(ARISMoviePlayer.moviePlayer.loadState & MPMovieLoadStatePlayable)
        //[ARISMoviePlayer.moviePlayer play];
}

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)audioPlayer successfully:(BOOL)flag
{
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void) displayTab:(NSString *)t
{
    
}

- (void) collapseView:(ARISCollapseView *)cv wasDragged:(UIPanGestureRecognizer *)r
{
    if(r.state == UIGestureRecognizerStateBegan) 
        [delegate scriptElementViewRequestsHideContinue:YES];
}

- (void) collapseView:(ARISCollapseView *)cv didStartOpen:(BOOL)o
{
    [delegate scriptElementViewRequestsHideContinue:!o];
}

- (BOOL) displayGameObject:(id<GameObjectProtocol>)g fromSource:(id)s
{
    return NO;
}

- (void) displayScannerWithPrompt:(NSString *)p
{
    
}

@end
