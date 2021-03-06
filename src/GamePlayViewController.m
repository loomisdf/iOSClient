//
//  GamePlayViewController.m
//  ARIS
//
//  Created by Phil Dougherty on 5/2/13.
//
//

#import "GamePlayViewController.h"

#import "ARISAlertHandler.h"
#import "ARISNavigationController.h"
#import "ARISWebView.h"

#import "GameNotificationViewController.h"
#import "LoadingIndicatorViewController.h"
#import "DisplayQueueModel.h"
#import "AppModel.h"

#import "GamePlayTabSelectorViewController.h"
#import "PKRevealController.h"

#import "QuestsViewController.h"
#import "IconQuestsViewController.h"
#import "InventoryViewController.h"
#import "MapViewController.h"
#import "AttributesViewController.h"
#import "NotebookViewController.h"
#import "DecoderViewController.h"

#import "PlaqueViewController.h"
#import "ItemViewController.h"
#import "DialogViewController.h"
#import "WebPageViewController.h"
#import "NoteViewController.h"

//needed for orientation hack
#import "AudioVisualizerViewController.h"

@interface GamePlayViewController() <
  UINavigationControllerDelegate,
  InstantiableViewControllerDelegate,
  GamePlayTabBarViewControllerDelegate,

  QuestsViewControllerDelegate,
  MapViewControllerDelegate,
  InventoryViewControllerDelegate,
  AttributesViewControllerDelegate,
  NotebookViewControllerDelegate,
  DecoderViewControllerDelegate,

  PlaqueViewControllerDelegate,
  ItemViewControllerDelegate,
  DialogViewControllerDelegate,
  WebPageViewControllerDelegate,
  NoteViewControllerDelegate,

  GamePlayTabSelectorViewControllerDelegate,
  GameNotificationViewControllerDelegate,
  LoadingIndicatorViewControllerDelegate,
  ARISWebViewDelegate
  >
{
  PKRevealController *gamePlayRevealController;
  GamePlayTabSelectorViewController *gamePlayTabSelectorController;
  ARISNavigationController *instantiableViewController;
  GameNotificationViewController *gameNotificationViewController;
  LoadingIndicatorViewController *loadingIndicatorViewController;
  NSTimer *tickerTimer;
  ARISWebView *ticker;
  
  //queue of dequeued instances to be displayed but were not yet loaded
  //yes, the fact that we need this second layer of queue points
  //to something being wrong with our architecture.
  //the culprit is the global nature of all our services.
  //the fact that we send off a global event and wait for another
  //global event yields too many oportunities for the code flow
  //to go somewhere else or stop and never come back, potentially leaving us
  //in an invalid state. hopefully this provides a sufficient temporary
  //buffer to protect us from that...
  NSMutableArray *local_inst_queue;
  
  id<GamePlayViewControllerDelegate> __unsafe_unretained delegate;
}

@end

@implementation GamePlayViewController

- (id) initWithDelegate:(id<GamePlayViewControllerDelegate>)d
{
  if(self = [super init])
  {
    delegate = d;
    
    gameNotificationViewController = [[GameNotificationViewController alloc] initWithDelegate:self];
    loadingIndicatorViewController = [[LoadingIndicatorViewController alloc] initWithDelegate:self];
    gamePlayTabSelectorController = [[GamePlayTabSelectorViewController alloc] initWithDelegate:self];
    gamePlayRevealController = [PKRevealController revealControllerWithFrontViewController:gamePlayTabSelectorController.firstViewController leftViewController:gamePlayTabSelectorController options:nil];
    
    local_inst_queue = [[NSMutableArray alloc] init];
    _ARIS_NOTIF_LISTEN_(@"MODEL_INSTANCES_PLAYER_AVAILABLE", self, @selector(flushBufferQueuedInstances), nil);
    _ARIS_NOTIF_LISTEN_(@"MODEL_DISPLAY_NEW_ENQUEUED", self, @selector(tryDequeue), nil);
  }
  return self;
}

- (void) loadView
{
  [super loadView];

  gameNotificationViewController.view.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);
  loadingIndicatorViewController.view.frame = CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height);
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  if(!currentChildViewController)
  {
    [self displayContentController:gamePlayRevealController];
    [self reSetOverlayControllersInVC:self atYDelta:0];
  }
}

- (void) viewDidAppear:(BOOL)animated
{
    [self tryDequeue];
}

- (void) gamePlayTabBarViewControllerRequestsNav
{
    [self showNav];
}

- (void) showNav
{
    [gamePlayRevealController showViewController:gamePlayTabSelectorController];
}

- (void) viewControllerRequestedDisplay:(ARISNavigationController *)avc
{
    [gamePlayRevealController setFrontViewController:avc];
    [gamePlayRevealController showViewController:avc];
}

- (BOOL) doDequeue
{
    NSObject *o;
    if((o = [_MODEL_DISPLAY_QUEUE_ dequeue]))
    {
        if     ([o isKindOfClass:[Trigger class]])  [self displayTrigger:(Trigger *)o];
        else if([o isKindOfClass:[Instance class]]) [self displayInstance:(Instance *)o];
        else if([o isKindOfClass:[Tab class]])      [self displayTab:(Tab *)o];
        else if([o conformsToProtocol:@protocol(InstantiableProtocol)]) [self displayObject:(NSObject <InstantiableProtocol>*)o];
        else return NO;
        return YES;
    } else {
        return NO;
    }
}

- (void) tryDequeue
{
    //Doesn't currently have the view-heirarchy authority to display.
    //if(!(self.isViewLoaded && self.view.window)) //should work but apple's timing is terrible
    if(instantiableViewController) return;
    [self doDequeue];
}

- (void) flushBufferQueuedInstances
{
  for(int i = 0; i < local_inst_queue.count; i++)
  {
    Instance *inst = [_MODEL_INSTANCES_ instanceForId:((NSNumber *)local_inst_queue[i]).longValue];
    if(inst.instance_id)
    {
      [_MODEL_DISPLAY_QUEUE_ enqueueInstance:inst];
      [local_inst_queue removeObjectAtIndex:i];
      i--;
    }
  }
}

- (void) displayTrigger:(Trigger *)t
{
    Instance *i = [_MODEL_INSTANCES_ instanceForId:t.instance_id];
    if(!i.instance_id)
    {
      //this is bad and points to a need for a non-global service architecture.
      //see notes by 'local_inst_queue'
      [local_inst_queue addObject:[NSNumber numberWithLong:t.instance_id]];
    }
    else
    {
      _ARIS_NOTIF_SEND_(@"GAME_PLAY_DISPLAYED_TRIGGER",nil,@{@"trigger":t});
      [self displayInstance:i];
      [_MODEL_LOGS_ playerTriggeredTriggerId:t.trigger_id];
    }
}

- (void) displayInstance:(Instance *)i
{
    ARISViewController *vc;
    if([i.object_type isEqualToString:@"PLAQUE"])
      vc = [[PlaqueViewController alloc] initWithInstance:i delegate:self];
    if([i.object_type isEqualToString:@"ITEM"])
        vc = [[ItemViewController alloc] initWithInstance:i delegate:self];
    if([i.object_type isEqualToString:@"DIALOG"])
        vc = [[DialogViewController alloc] initWithInstance:i delegate:self];
    if([i.object_type isEqualToString:@"WEB_PAGE"])
        vc = [[WebPageViewController alloc] initWithInstance:i delegate:self];
    if([i.object_type isEqualToString:@"NOTE"])
        vc = [[NoteViewController alloc] initWithInstance:i delegate:self];
    if([i.object_type isEqualToString:@"EVENT_PACKAGE"]) //Special case (don't actually display anything)
    {
        [_MODEL_EVENTS_ runEventPackageId:i.object_id]; //will take care of log
        //Hack 'dequeue' as simulation for normally inevitable request dismissal of VC we didn't put up...
        [self performSelector:@selector(tryDequeue) withObject:nil afterDelay:1];
        return;
    }
    if([i.object_type isEqualToString:@"SCENE"]) //Special case (don't actually display anything)
    {
        [_MODEL_SCENES_ setPlayerScene:(Scene *)i.object];
        [_MODEL_LOGS_ playerViewedInstanceId:i.instance_id];
        //Hack 'dequeue' as simulation for normally inevitable request dismissal of VC we didn't put up...
        [self performSelector:@selector(tryDequeue) withObject:nil afterDelay:1];
        return;
    }
    if([i.object_type isEqualToString:@"EVENT_PACKAGE"]) //Special case (don't actually display anything)
    {
        [_MODEL_EVENTS_ runEventPackageId:i.object_id];
        [_MODEL_LOGS_ playerViewedInstanceId:i.instance_id];
        //Hack 'dequeue' as simulation for normally inevitable request dismissal of VC we didn't put up...
        [self performSelector:@selector(tryDequeue) withObject:nil afterDelay:1];
        return;
    }
    if([i.object_type isEqualToString:@"FACTORY"]) //Special case (don't actually display anything)
    {
        //Hack 'dequeue' as simulation for normally inevitable request dismissal of VC we didn't put up...
        [self performSelector:@selector(tryDequeue) withObject:nil afterDelay:1];
        return;
    }
    [_MODEL_LOGS_ playerViewedInstanceId:i.instance_id];
    _ARIS_NOTIF_SEND_(@"GAME_PLAY_DISPLAYED_INSTANCE",nil,@{@"instance":i});
    if(i.factory_id)
    {
        Factory *f = [_MODEL_FACTORIES_ factoryForId:i.factory_id];
        if(f.produce_expire_on_view)
            [_MODEL_TRIGGERS_ expireTriggersForInstanceId:i.instance_id];
    }

    [self presentInstantiableViewController:[[ARISNavigationController alloc] initWithRootViewController:vc]];
}

- (void) displayObject:(NSObject <InstantiableProtocol>*)o
{
    ARISViewController *vc;
    Instance *i = [_MODEL_INSTANCES_ instanceForId:0];
    if([o isKindOfClass:[Plaque class]])
    {
      Plaque *p = (Plaque *)o;
      i.object_type = @"PLAQUE";
      i.object_id = p.plaque_id;
      vc = [[PlaqueViewController alloc] initWithInstance:i delegate:self];
    }
    else if([o isKindOfClass:[Item class]])
    {
      Item *it = (Item *)o;
      i.object_type = @"ITEM";
      i.object_id = it.item_id;
      vc = [[ItemViewController alloc] initWithInstance:i delegate:self];
    }
    else if([o isKindOfClass:[Dialog class]])
    {
      Dialog *d = (Dialog *)o;
      i.object_type = @"DIALOG";
      i.object_id = d.dialog_id;
      vc = [[DialogViewController alloc] initWithInstance:i delegate:self];
    }
    else if([o isKindOfClass:[WebPage class]])
    {
      WebPage *w = (WebPage *)o;
      if(w.web_page_id == 0) //assume ad hoc (created from some webview href maybe?)
      {
        vc = [[WebPageViewController alloc] initWithWebPage:w delegate:self];
      }
      else
      {
        i.object_type = @"WEB_PAGE";
        i.object_id = w.web_page_id;
        vc = [[WebPageViewController alloc] initWithInstance:i delegate:self];
      }
    }
    else if([o isKindOfClass:[Note class]])
    {
      Note *n = (Note *)o;
      i.object_type = @"NOTE";
      i.object_id = n.note_id;
      vc = [[NoteViewController alloc] initWithInstance:i delegate:self];
    }

    [self presentInstantiableViewController:[[ARISNavigationController alloc] initWithRootViewController:vc]];
}

- (void) presentInstantiableViewController:(ARISNavigationController *)viewToDisplay
{
    [self displayContentController:viewToDisplay];

    [self reSetOverlayControllersInVC:viewToDisplay atYDelta:20];
    
    instantiableViewController = viewToDisplay;
}

- (void) instantiableViewControllerRequestsDismissal:(id<InstantiableViewControllerProtocol>)ivc
{
    [_MODEL_LOGS_ playerViewedContent:ivc.instance.object_type id:ivc.instance.object_id];
    if(![self doDequeue] && instantiableViewController.viewControllers[0] == ivc)
    {
        [self displayContentController:gamePlayRevealController];
        instantiableViewController = nil;
    }
    [self reSetOverlayControllersInVC:self atYDelta:-20];
}

- (void) reSetOverlayControllersInVC:(UIViewController *)vc atYDelta:(int)ydelt
{
    //Phil hates that the frame changes depending on what view you add it to...
    gameNotificationViewController.view.frame = CGRectMake(gameNotificationViewController.view.frame.origin.x,
                                                           gameNotificationViewController.view.frame.origin.y+ydelt,
                                                           gameNotificationViewController.view.frame.size.width,
                                                           gameNotificationViewController.view.frame.size.height);

    loadingIndicatorViewController.view.frame = CGRectMake(loadingIndicatorViewController.view.frame.origin.x,
                                                           loadingIndicatorViewController.view.frame.origin.y+ydelt,
                                                           loadingIndicatorViewController.view.frame.size.width,
                                                           loadingIndicatorViewController.view.frame.size.height);

    [vc.view addSubview:gameNotificationViewController.view];
    //[vc.view addSubview:loadingIndicatorViewController.view]; //disabled for now (should work fine though!)
}

- (void) displayTab:(Tab *)t
{
    [self displayContentController:gamePlayRevealController];
    instantiableViewController = nil;
    
    [gamePlayTabSelectorController requestDisplayTab:t];
    [self tryDequeue]; //no 'closing event' for tab
}
- (void) displayScannerWithPrompt:(NSString *)p
{
    [gamePlayTabSelectorController requestDisplayScannerWithPrompt:p];
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait;
}
- (BOOL) shouldAutorotate
{
  return NO;
}

- (void) tickTicker
{
  [ticker tickWithParams:@""];
}

- (void) destroy //wouldn't be necessary if you could reliably dealloc...
{
  if(tickerTimer) [tickerTimer invalidate];
}

- (void) dealloc
{
  [self destroy];
  _ARIS_NOTIF_IGNORE_ALL_(self);
}

- (BOOL) viewingObject
{
    if (instantiableViewController) {
        return YES;
    }
    else {
        return NO;
    }
}

@end
