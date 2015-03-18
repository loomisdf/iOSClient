//
//  ItemsModel.m
//  ARIS
//
//  Created by Phil Dougherty on 2/13/13.
//
//

// RULE OF THUMB:
// Merge any new object data rather than replace. Becuase 'everything is pointers' in obj c, 
// we can't know what data we're invalidating by replacing a ptr

#import "ItemsModel.h"
#import "AppServices.h"
#import "AppModel.h"

@interface ItemsModel()
{
    NSMutableDictionary *items;
    NSMutableDictionary *playerItemInstances;

    NSMutableArray *inventory;
    NSMutableArray *attributes;
}

@end

@implementation ItemsModel

@synthesize currentWeight;
@synthesize weightCap;

- (id) init
{
    if(self = [super init])
    {
        [self clearGameData];
        _ARIS_NOTIF_LISTEN_(@"SERVICES_ITEMS_RECEIVED",self,@selector(itemsReceived:),nil);
        _ARIS_NOTIF_LISTEN_(@"SERVICES_ITEMS_TOUCHED",self,@selector(itemsTouched:),nil);
        _ARIS_NOTIF_LISTEN_(@"MODEL_INSTANCES_PLAYER_AVAILABLE",self,@selector(playerInstancesAvailable),nil);
    }
    return self;
}

- (void) clearPlayerData
{
    playerItemInstances = [[NSMutableDictionary alloc] init];
    [self invalidateCaches];
    currentWeight = 0;
}

- (void) invalidateCaches
{
    inventory = nil;
    attributes = nil;
}

- (void) clearGameData
{
    [self clearPlayerData];
    items = [[NSMutableDictionary alloc] init];
    weightCap = 0;
}

- (void) itemsReceived:(NSNotification *)notif
{
    [self updateItems:[notif.userInfo objectForKey:@"items"]];
}
- (void) itemsTouched:(NSNotification *)notif
{
    _ARIS_NOTIF_SEND_(@"MODEL_ITEMS_TOUCHED",nil,nil);   
    _ARIS_NOTIF_SEND_(@"MODEL_GAME_PIECE_AVAILABLE",nil,nil);      
}

- (void) updateItems:(NSArray *)newItems
{
    Item *newItem;
    NSNumber *newItemId;
    for(long i = 0; i < newItems.count; i++)
    {
      newItem = [newItems objectAtIndex:i];
      newItemId = [NSNumber numberWithLong:newItem.item_id];
      if(![items objectForKey:newItemId]) [items setObject:newItem forKey:newItemId];
    }
    _ARIS_NOTIF_SEND_(@"MODEL_ITEMS_AVAILABLE",nil,nil);   
    _ARIS_NOTIF_SEND_(@"MODEL_GAME_PIECE_AVAILABLE",nil,nil);      
}

- (void) requestItems
{
    [_SERVICES_ fetchItems]; 
}
- (void) touchPlayerItemInstances
{
    [_SERVICES_ touchItemsForPlayer]; 
}

- (void) playerInstancesAvailable
{
    NSArray *newInstances = [_MODEL_INSTANCES_ playerInstances];
    [self clearPlayerData];
    
    Instance *newInstance;
    for(long i = 0; i < newInstances.count; i++)
    {
        newInstance = newInstances[i];
        if(![newInstance.object_type isEqualToString:@"ITEM"] || newInstance.owner_id != _MODEL_PLAYER_.user_id) continue;
        
        playerItemInstances[[NSNumber numberWithLong:newInstance.object_id]] = newInstance;
    }
    _ARIS_NOTIF_SEND_(@"MODEL_ITEMS_PLAYER_INSTANCES_AVAILABLE",nil,nil);
}

- (long) dropItemFromPlayer:(long)item_id qtyToRemove:(long)qty
{
    Instance *pII = playerItemInstances[[NSNumber numberWithLong:item_id]];
    if(!pII) return 0; //UH OH! NO INSTANCE TO TAKE ITEM FROM! (shouldn't happen if touchItemsForPlayer was called...)
    if(pII.qty < qty) qty = pII.qty;
    
    [_SERVICES_ dropItem:(long)item_id qty:(long)qty];
    return [self takeItemFromPlayer:item_id qtyToRemove:qty];
}

- (long) takeItemFromPlayer:(long)item_id qtyToRemove:(long)qty
{
  Instance *pII = playerItemInstances[[NSNumber numberWithLong:item_id]];
  if(!pII) return 0; //UH OH! NO INSTANCE TO TAKE ITEM FROM! (shouldn't happen if touchItemsForPlayer was called...)
  if(pII.qty < qty) qty = pII.qty;
    
  return [self setItemsForPlayer:item_id qtyToSet:pII.qty-qty];
}

- (long) giveItemToPlayer:(long)item_id qtyToAdd:(long)qty
{
  Instance *pII = playerItemInstances[[NSNumber numberWithLong:item_id]];
  if(!pII) return 0; //UH OH! NO INSTANCE TO GIVE ITEM TO! (shouldn't happen if touchItemsForPlayer was called...)
  if(qty > [self qtyAllowedToGiveForItem:item_id]) qty = [self qtyAllowedToGiveForItem:item_id];
    
  return [self setItemsForPlayer:item_id qtyToSet:pII.qty+qty];
}

- (long) setItemsForPlayer:(long)item_id qtyToSet:(long)qty
{
  [self invalidateCaches];
  Instance *pII = playerItemInstances[[NSNumber numberWithLong:item_id]];
  if(!pII) return 0; //UH OH! NO INSTANCE TO GIVE ITEM TO! (shouldn't happen if touchItemsForPlayer was called...)
  if(qty < 0) qty = 0;
  if(qty-pII.qty > [self qtyAllowedToGiveForItem:item_id]) qty = pII.qty+[self qtyAllowedToGiveForItem:item_id];

  long oldQty = pII.qty;
  [_MODEL_INSTANCES_ setQtyForInstanceId:pII.instance_id qty:qty];
  if(qty > oldQty)
  {
      [_MODEL_LOGS_ playerReceivedItemId:item_id qty:qty];
      
      //Instance model notifs. #dealwithit
      NSDictionary *deltas = @{@"lost":@[],@"added":@[@{@"instance":pII,@"delta":[NSNumber numberWithLong:qty-oldQty]}]}; //ridiculous construct...
      _ARIS_NOTIF_SEND_(@"MODEL_INSTANCES_PLAYER_GAINED",nil,deltas);
  }
  if(qty < oldQty)
  {
      [_MODEL_LOGS_ playerLostItemId:item_id qty:qty];
      
      //Instance model notifs. #dealwithit
      NSDictionary *deltas = @{@"added":@[],@"lost":@[@{@"instance":pII,@"delta":[NSNumber numberWithLong:qty-oldQty]}]}; //ridiculous construct...
      _ARIS_NOTIF_SEND_(@"MODEL_INSTANCES_PLAYER_LOST",nil,deltas);
  }
  _ARIS_NOTIF_SEND_(@"MODEL_INSTANCES_PLAYER_AVAILABLE",nil,nil);
    
  return qty;
}

// null item (id == 0) NOT flyweight!!! (to allow for temporary customization safety)
- (Item *) itemForId:(long)item_id
{
  if(!item_id) return [[Item alloc] init]; 
  return [items objectForKey:[NSNumber numberWithLong:item_id]];
}

- (long) qtyOwnedForItem:(long)item_id
{
    return ((Instance *)playerItemInstances[[NSNumber numberWithLong:item_id]]).qty;
}

- (long) qtyAllowedToGiveForItem:(long)item_id
{
    Item *i = [self itemForId:item_id]; 
    long amtMoreCanHold = i.max_qty_in_inventory-[self qtyOwnedForItem:item_id];
    while(weightCap != 0 && 
          (amtMoreCanHold*i.weight + currentWeight) > weightCap)
        amtMoreCanHold--; 
    
    return amtMoreCanHold;
}

- (NSArray *) inventory
{
  if(inventory) return inventory;

  inventory = [[NSMutableArray alloc] init];
  NSArray *instancearray = [playerItemInstances allValues];
  for(long i = 0; i < instancearray.count; i++)
  {
      if([((Item *)((Instance *)[instancearray objectAtIndex:i]).object).type isEqualToString:@"NORMAL"]) 
      [inventory addObject:[instancearray objectAtIndex:i]];
  }
  return inventory;
}

- (NSArray *) attributes
{
  if(attributes) return attributes;

  attributes = [[NSMutableArray alloc] init];
  NSArray *instancearray = [playerItemInstances allValues];
  for(long i = 0; i < instancearray.count; i++)
  {
      if([((Item *)((Instance *)[instancearray objectAtIndex:i]).object).type isEqualToString:@"ATTRIB"]) 
          [attributes addObject:[instancearray objectAtIndex:i]]; 
  }
  return attributes;
}

- (void) dealloc
{
    _ARIS_NOTIF_IGNORE_ALL_(self);               
}

@end