//
//  Instance.m
//  ARIS
//
//  Created by David Gagnon on 4/1/09.
//  Copyright 2009 University of Wisconsin - Madison. All rights reserved.
//

#import "Instance.h"
#import "AppModel.h"
#import "AppServices.h"
#import "NSDictionary+ValidParsers.h"
#import "NSString+JSON.h"

@implementation Instance

@synthesize instance_id;
@synthesize object_type;
@synthesize object_id;
@synthesize owner_type;
@synthesize owner_id;
@synthesize qty;
@synthesize infinite_qty;
@synthesize factory_id;
@synthesize created;

- (id) init
{
  if(self = [super init])
  {
    self.instance_id = 0;
    self.object_type = @"";
    self.object_id = 0;
    self.owner_type = @"";
    self.owner_id = 0;
    self.qty = 0;
    self.infinite_qty = NO;
    self.factory_id = 0;
    self.created = [NSDate date];
  }
  return self;
}

- (id) initWithDictionary:(NSDictionary *)dict
{
  if(self = [super init])
  {
    self.instance_id = [dict validIntForKey:@"instance_id"];
    self.object_type = [dict validStringForKey:@"object_type"];
    self.object_id = [dict validIntForKey:@"object_id"];
    self.owner_type = [dict validStringForKey:@"owner_type"];
    self.owner_id = [dict validIntForKey:@"owner_id"];
    self.qty = [dict validIntForKey:@"qty"];
    self.infinite_qty = [dict validBoolForKey:@"infinite_qty"];
    self.factory_id = [dict validIntForKey:@"factory_id"];
    //self.created = [dict validDateForKey:@"created"]; //can't trust? out of sync?
    self.created = [NSDate date];
  }
  return self;
}

- (NSString *) serialize
{
  NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
  [d setObject:[NSString stringWithFormat:@"%ld",self.instance_id] forKey:@"instance_id"];
  [d setObject:self.object_type forKey:@"object_type"];
  [d setObject:[NSString stringWithFormat:@"%ld",self.object_id] forKey:@"object_id"];
  [d setObject:self.owner_type forKey:@"owner_type"];
  [d setObject:[NSString stringWithFormat:@"%ld",self.owner_id] forKey:@"owner_id"];
  [d setObject:[NSString stringWithFormat:@"%ld",self.qty] forKey:@"qty"];
  [d setObject:[NSString stringWithFormat:@"%d",self.infinite_qty] forKey:@"infinite_qty"];
  [d setObject:[NSString stringWithFormat:@"%ld",self.factory_id] forKey:@"factory_id"];
  [d setObject:[self.created descriptionWithLocale:nil] forKey:@"created"];
  return [NSString JSONFromFlatStringDict:d];
}

- (void) mergeDataFromInstance:(Instance *)i
{
  self.instance_id = i.instance_id;
  self.object_type = i.object_type;
  self.object_id = i.object_id;
  self.owner_type = i.owner_type;
  self.owner_id = i.owner_id;
  self.qty = i.qty;
  self.infinite_qty = i.infinite_qty;
  self.factory_id = i.factory_id;
  //self.created = i.created; //can't trust (see above)
  if(!self.created) self.created = i.created;
}

- (Instance *) copy
{
  Instance *c = [[Instance alloc] init];

  c.instance_id = self.instance_id;
  c.object_type = self.object_type;
  c.object_id = self.object_id;
  c.owner_type = self.owner_type;
  c.owner_id = self.owner_id;
  c.qty = self.qty;
  c.infinite_qty = self.infinite_qty;
  c.factory_id = self.factory_id;
  c.created = self.created;

  return c;
}

- (id<InstantiableProtocol>) object
{
  if([self.object_type isEqualToString:@"ITEM"])          return [_MODEL_ITEMS_ itemForId:         self.object_id];
  if([self.object_type isEqualToString:@"PLAQUE"])        return [_MODEL_PLAQUES_ plaqueForId:     self.object_id];
  if([self.object_type isEqualToString:@"WEB_PAGE"])      return [_MODEL_WEB_PAGES_ webPageForId:  self.object_id];
  if([self.object_type isEqualToString:@"DIALOG"])        return [_MODEL_DIALOGS_ dialogForId:     self.object_id];
  if([self.object_type isEqualToString:@"EVENT_PACKAGE"]) return [_MODEL_EVENTS_ eventPackageForId:self.object_id];
  if([self.object_type isEqualToString:@"SCENE"])         return [_MODEL_SCENES_ sceneForId:       self.object_id];
  if([self.object_type isEqualToString:@"NOTE"])
  {
    if(![_MODEL_NOTES_ noteForId:self.object_id])
      [_SERVICES_ fetchNoteById:self.object_id];
    return [_MODEL_NOTES_ noteForId:self.object_id];
  }
  return nil;
}

- (NSString *) name
{
  return [self object].name;
}

- (long) icon_media_id
{
  return [self object].icon_media_id;
}

@end

