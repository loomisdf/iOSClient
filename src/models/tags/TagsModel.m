//
//  TagsModel.m
//  ARIS
//
//  Created by Phil Dougherty on 2/13/13.
//
//

// RULE OF THUMB:
// Merge any new object data rather than replace. Becuase 'everything is pointers' in obj c,
// we can't know what data we're invalidating by replacing a ptr

#import "TagsModel.h"
#import "AppServices.h"

@interface TagsModel()
{
    NSMutableDictionary *tags;
    NSMutableDictionary *objectTags;
}

@end

@implementation TagsModel

- (id) init
{
    if(self = [super init])
    {
        [self clearGameData];
        _ARIS_NOTIF_LISTEN_(@"SERVICES_TAGS_RECEIVED",self,@selector(tagsReceived:),nil);
        _ARIS_NOTIF_LISTEN_(@"SERVICES_OBJECT_TAGS_RECEIVED",self,@selector(objectTagsReceived:),nil);
    }
    return self;
}

- (void) clearGameData
{
    tags = [[NSMutableDictionary alloc] init];
    objectTags = [[NSMutableDictionary alloc] init];
}

- (void) tagsReceived:(NSNotification *)notif
{
    [self updateTags:[notif.userInfo objectForKey:@"tags"]];
}
- (void) objectTagsReceived:(NSNotification *)notif
{
    [self updateObjectTags:[notif.userInfo objectForKey:@"object_tags"]];
}

- (void) updateTags:(NSArray *)newTags
{
    Tag *newTag;
    NSNumber *newTagId;
    for(long i = 0; i < newTags.count; i++)
    {
      newTag = [newTags objectAtIndex:i];
      newTagId = [NSNumber numberWithLong:newTag.tag_id];
      if(![tags objectForKey:newTagId]) [tags setObject:newTag forKey:newTagId];
    }
    _ARIS_NOTIF_SEND_(@"MODEL_TAGS_AVAILABLE",nil,nil);
    _ARIS_NOTIF_SEND_(@"MODEL_GAME_PIECE_AVAILABLE",nil,nil);
}

- (void) updateObjectTags:(NSArray *)newObjectTags
{
    ObjectTag *newObjectTag;
    NSNumber *newObjectTagId;
    for(long i = 0; i < newObjectTags.count; i++)
    {
      newObjectTag = [newObjectTags objectAtIndex:i];
      newObjectTagId = [NSNumber numberWithLong:newObjectTag.object_tag_id];
      if(![objectTags objectForKey:newObjectTagId]) [objectTags setObject:newObjectTag forKey:newObjectTagId];
    }
    _ARIS_NOTIF_SEND_(@"MODEL_OBJECT_TAGS_AVAILABLE",nil,nil);
    _ARIS_NOTIF_SEND_(@"MODEL_GAME_PIECE_AVAILABLE",nil,nil);
}

- (void) requestTags
{
    [_SERVICES_ fetchTags];
    [_SERVICES_ fetchObjectTags];
}

- (NSArray *) tagsForObjectType:(NSString*)t id:(long)object_id
{
    ObjectTag *otag;
    NSArray *otags = [objectTags allValues];
    NSMutableArray *objects_tags = [[NSMutableArray alloc] init];
    for(long i = 0; i < otags.count; i++)
    {
        otag = otags[i];
        if([otag.object_type isEqualToString:t] && otag.object_id == object_id)
            [objects_tags addObject:[self tagForId:otag.tag_id]];
    }
    return objects_tags;
}

- (void) removeTagsFromObjectType:(NSString*)t id:(long)object_id
{
    ObjectTag *otag;
    NSArray *otags = [objectTags allValues];
    for(long i = 0; i < otags.count; i++)
    {
        otag = otags[i];
        if([otag.object_type isEqualToString:t] && otag.object_id == object_id)
        {
          [objectTags removeObjectForKey: [NSNumber numberWithLong:otag.object_tag_id]];
        }
    }
}

- (NSArray *) tags
{
    return [tags allValues];
}
    
// null tag (id == 0) NOT flyweight!!! (to allow for temporary customization safety)
- (Tag *) tagForId:(long)tag_id
{
  if(!tag_id) return [[Tag alloc] init];
  return [tags objectForKey:[NSNumber numberWithLong:tag_id]];
}

// null objectTag (id == 0) NOT flyweight!!! (to allow for temporary customization safety)
- (ObjectTag *) objectTagForId:(long)object_tag_id
{
  if(!object_tag_id) return [[ObjectTag alloc] init];
  return [objectTags objectForKey:[NSNumber numberWithLong:object_tag_id]];
}

- (void) dealloc
{
    _ARIS_NOTIF_IGNORE_ALL_(self);
}

@end