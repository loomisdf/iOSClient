//
//  NoteTagEditorViewController.h
//  ARIS
//
//  Created by Phil Dougherty on 11/8/13.
//
//

#import "ARISViewController.h"

@class NoteTag;

@protocol NoteTagEditorViewControllerDelegate
@optional
- (void) noteTagEditorAddedTag:(NoteTag *)nt;
- (void) noteTagEditorCreatedTag:(NoteTag *)nt;
- (void) noteTagEditorWillBeginEditing;
@end

@interface NoteTagEditorViewController : ARISViewController
- (id) initWithTags:(NSArray *)t editable:(BOOL)e delegate:(id<NoteTagEditorViewControllerDelegate>)d;
- (void) setTags:(NSArray *)t;
- (void) stopEditing;
@end
