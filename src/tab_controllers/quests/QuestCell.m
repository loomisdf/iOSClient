//
//  QuestCell.m
//  ARIS
//
//  Created by Phil Dougherty on 2/27/14.
//
//

#import "QuestCell.h"
#import "Quest.h"
#import "ARISWebView.h"

@interface QuestCell () <ARISWebViewDelegate, StateControllerProtocol>
{
	UILabel *titleView;
   	ARISWebView *descriptionView; 
    
    Quest *quest;
    id<QuestCellDelegate> __unsafe_unretained delegate;
}
@end

@implementation QuestCell

- (id) init
{
    if(self = [super init])
    {
        [self initializeViews];
    }
    return self;
}

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        [self initializeViews]; 
    }
    return self;
}

- (void) setDelegate:(id<QuestCellDelegate>)d
{
    delegate = d;
}

- (void) initializeViews
{
    titleView = [[UILabel alloc] init];
    descriptionView = [[ARISWebView alloc] initWithDelegate:self]; 
    
    titleView.font = [ARISTemplate ARISCellTitleFont];
    descriptionView.scrollView.scrollEnabled = NO;
    
    titleView.frame = CGRectMake(10,10,self.frame.size.width-20,20);  
    descriptionView.frame = CGRectMake(0, 20, self.frame.size.width, 15);
    
    titleView.userInteractionEnabled = NO;  
    descriptionView.userInteractionEnabled = NO;   
    
    [self addSubview:titleView];
    [self addSubview:descriptionView];
}

- (void) setQuest:(Quest *)q
{
    quest = q;
    titleView.text = quest.name; 
    descriptionView.frame = CGRectMake(0,20,self.frame.size.width,15);
    [descriptionView loadHTMLString:[NSString stringWithFormat:[ARISTemplate ARISHtmlTemplate], q.desc] baseURL:nil];   
}

- (void) ARISWebViewDidFinishLoad:(ARISWebView *)wv
{
    float newHeight = [[wv stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"] floatValue]; 
    descriptionView.frame = CGRectMake(0,20,self.frame.size.width,newHeight);
    [delegate heightCalculated:descriptionView.frame.origin.y+descriptionView.frame.size.height forQuest:quest inCell:self];
}

//implement statecontrol stuff for webpage, but just delegate any requests
- (BOOL) displayTrigger:(Trigger *)t   { return NO; }
- (BOOL) displayTriggerId:(int)t       { return NO; }
- (BOOL) displayInstance:(Instance *)i { return NO; }
- (BOOL) displayInstanceId:(int)i      { return NO; }
- (BOOL) displayObject:(id)o           { return NO; }
- (BOOL) displayObjectType:(NSString *)type id:(int)type_id { return NO; }
- (void) displayTab:(Tab *)t           { }
- (void) displayTabId:(int)t           { }
- (void) displayTabType:(NSString *)t  { }
- (void) displayScannerWithPrompt:(NSString *)p { }

@end
