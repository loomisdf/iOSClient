//
//  GamePickerAnywhereViewController.m
//  ARIS
//
//  Created by Ben Longoria on 2/13/09.
//  Copyright 2009 University of Wisconsin. All rights reserved.
//

#include <QuartzCore/QuartzCore.h>
#import "GamePickerAnywhereViewController.h"
#import "AppModel.h"

@implementation GamePickerAnywhereViewController

- (id) initWithDelegate:(id<GamePickerViewControllerDelegate>)d
{
    if(self = [super initWithDelegate:d])
    {
        self.title = NSLocalizedString(@"GamePickerAnywhereTabKey", @"");
        [self.tabBarItem setImage:[[UIImage imageNamed:@"globe.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [self.tabBarItem setSelectedImage:[[UIImage imageNamed:@"globe_red.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];

        _ARIS_NOTIF_LISTEN_(@"MODEL_ANYWHERE_GAMES_AVAILABLE",self,@selector(anywhereGamesAvailable),nil);
    }
    return self;
}

- (void) anywhereGamesAvailable
{
    [self removeLoadingIndicator];
  games = _MODEL_GAMES_.anywhereGames;
    [gameTable reloadData];
}
- (void) refreshViewFromModel
{
  games = _MODEL_GAMES_.pingAnywhereGames;
    [gameTable reloadData];
}

- (void) dealloc
{
    _ARIS_NOTIF_IGNORE_ALL_(self);
}

@end
