//
//  NoteTagPredictionViewController.h
//  ARIS
//
//  Created by Phil Dougherty on 1/27/14.
//
//

#import <UIKit/UIKit.h>

@class NoteTag;

@protocol NoteTagPredictionViewControllerDelegate
- (void) existingTagChosen:(NoteTag *)nt;
@end

@interface NoteTagPredictionViewController : UIViewController
- (id) initWithGameNoteTags:(NSArray *)gnt playerNoteTags:(NSArray *)pnt delegate:(id<NoteTagPredictionViewControllerDelegate>)d;
- (NSDictionary *) queryString:(NSString *)qs;
@end
