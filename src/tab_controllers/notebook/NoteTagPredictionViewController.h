//
//  NoteTagPredictionViewController.h
//  ARIS
//
//  Created by Phil Dougherty on 1/27/14.
//
//

#import <UIKit/UIKit.h>

@protocol NoteTagPredictionViewControllerDelegate
//- (void) existingTagChosen:(NoteTag *)nt;
@end

@interface NoteTagPredictionViewController : UIViewController
- (id) initWithGameNoteTags:(NSArray *)gnt playerNoteTags:(NSArray *)pnt delegate:(id<NoteTagPredictionViewControllerDelegate>)d;
- (void) setGameNoteTags:(NSArray *)gnt playerNoteTags:(NSArray *)pnt;
- (NSDictionary *) queryString:(NSString *)qs;
@end
