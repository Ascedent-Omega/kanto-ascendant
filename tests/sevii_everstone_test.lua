local items={EVERSTONE={id='EVERSTONE',price=200}}
local function registry()
  return{get=function(_,id)return items[id]end,patch=function(_,id,fields)
    for k,v in pairs(fields)do items[id][k]=v end
  end}
end
local wrapped,priority
local profile={extensionsEnabled=true,activeEpoch=2}
local E=dofile('sevii_everstone.lua')({content={items=registry()},hooks={wrap=function(_,name,fn,p)
  assert(name=='evolution.check');wrapped=fn;priority=p
end}},{rules={peek=function()return profile end}})
local game={data={items=items}}
local mon={species='MAGIKARP',item='EVERSTONE',heldItem='EVERSTONE'}
local checks=0;local function check(value,reason)checks=checks+1;assert(value,reason)end
check(priority==9600 and items.EVERSTONE.kascSeviiEverstone==E.OWNER,'registered held effect owner')
check(E.supportsItem(game,'EVERSTONE',2),'equipment advertises Gen2 support')
check(not E.supportsItem(game,'EVERSTONE',1),'Gen1 equipment does not advertise effect')
check(E.held(mon)and E.blocks(game,mon,{kind='levelup'}),'held stone blocks levelup')
local calls=0;local function nextCheck()calls=calls+1;return true end
for _,kind in ipairs{'levelup','trade','item','manual'}do
  check(wrapped(nextCheck,game,mon,{}, {kind=kind})==false,'held stone blocks '..kind)
end
check(calls==0,'blocked evolution never reaches native check')
check(wrapped(nextCheck,game,mon,{}, {kind='item-check'})==true,'item preview still reads evolution')
mon.item=nil;mon.heldItem=nil
check(wrapped(nextCheck,game,mon,{}, {kind='levelup'})==true,'taking stone restores evolution')
mon.item='EVERSTONE';mon.heldItem='SOOTHE_BELL'
check(not E.held(mon)and wrapped(nextCheck,game,mon,{}, {kind='levelup'})==true,'conflicting aliases cannot grant effect')
mon.heldItem='EVERSTONE';profile.activeEpoch=1
check(wrapped(nextCheck,game,mon,{}, {kind='levelup'})==true,'Gen1 profile leaves evolution unchanged')
profile.activeEpoch=2;profile.extensionsEnabled=false
check(wrapped(nextCheck,game,mon,{}, {kind='levelup'})==true,'disabled extension leaves evolution unchanged')
profile.extensionsEnabled=true;mon.item='NO_ITEM'
check(E.held(mon)and E.blocks(game,mon,{kind='levelup'}),'old empty item alias admits heldItem')
print('PASS Sevii Everstone: '..checks..' checks')
