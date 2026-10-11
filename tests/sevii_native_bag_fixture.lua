-- Native full-pocket QA fixture, including engines with multiple stacks.
-- Uses only registered items so the fixture survives real save/load.
return function(game,item)
  local Bag=require('src.inventory.Bag')
  local oldInventory,oldOrder,oldStacks=game.save.inventory,game.save.bagOrder,game.save.inventoryStacks
  local pocket=Bag.pocketOf(item,game.data);local inventory={};local candidates={}
  for id,value in pairs(oldInventory)do
    if Bag.pocketOf(id,game.data)~=pocket then inventory[id]=value end
  end
  for id in pairs(game.data.items)do
    if id~=item and Bag.pocketOf(id,game.data)==pocket then candidates[#candidates+1]=id end
  end
  table.sort(candidates)
  local required=Bag.capacity(game.data,pocket)-1
  inventory[item]=99
  local filler
  for _,id in ipairs(candidates)do
    if Bag.slotsFor(id,198,game.data)==2 then filler=id;break end
  end
  if filler and required>0 then
    inventory[filler]=required*99
  else
    assert(#candidates>=required,'not enough registered items to fill reward pocket')
    for i=1,required do inventory[candidates[i]]=1 end
  end
  assert(Bag.storeSlots(inventory,game.data,function(id)
    return Bag.pocketOf(id,game.data)==pocket
  end)==Bag.capacity(game.data,pocket),'reward pocket is not full')
  game.save.inventory,game.save.bagOrder,game.save.inventoryStacks=inventory,nil,nil
  return function()
    game.save.inventory,game.save.bagOrder,game.save.inventoryStacks=oldInventory,oldOrder,oldStacks
  end
end
