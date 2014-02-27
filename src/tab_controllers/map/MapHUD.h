//
//  MapHUD.h
//  ARIS
//
//  Created by Phil Dougherty on 2/6/14.
//
//

#import <UIKit/UIKit.h>
#import "ARISWebView.h"
#import "Location.h"
#import "ARISCollapseView.h"

@protocol MapHUDDelegate
- (void) dismissHUDWithAnnotation:(MKAnnotationView *)annotation;
@end


@interface MapHUD : UIViewController
- (id) initWithDelegate:(id<MapHUDDelegate, StateControllerProtocol>)d withFrame:(CGRect)f;
- (void) setLocation:(Location *)l withAnnotation:(MKAnnotationView *)a;

@property (nonatomic, readwrite) MKAnnotationView *annotation;
@property (nonatomic, readwrite) ARISCollapseView *collapseView;
@end