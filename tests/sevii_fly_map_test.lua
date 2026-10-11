package.path=assert(os.getenv('KASC_ENGINE'))..'/?.lua;'..package.path
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local points,maps={},{}
local coords={{86,62},{189,131},{351,141},{299,52},{83,214},{224,241},{358,251}}
for island=1,7 do
  local id='SEVII_'..island
  points[island]={island=island,map=id,chartX=coords[island][1],chartY=coords[island][2]}
  maps[id]={id=id,kaSeviiIsland=island,outdoor=true,index=2100+island}
end
local unlocked=false
local expedition={available=true,maps=maps,flight={points=points,byMap={}}}
for _,point in ipairs(points)do expedition.flight.byMap[point.map]=point end
function expedition.flight.currentIsland(game)
  local id=game.overworld.map.id
  return maps[id]and maps[id].kaSeviiIsland or nil
end
function expedition.flight.visited(game,island)
  return game.save.chartVisited[island]==true
end
function expedition.flight.eligible(game,island)
  return unlocked and expedition.flight.visited(game,island)
end
function expedition.flight.unlocked()return unlocked end
function expedition.flight.chartUnlocked(game)
  return game.save.chartUnlocked==true
end
local originalTownMap={new=function()error('previous owner must be replaced')end}
local registered={TownMap=originalTownMap}
local startHook
local mod={path='.',exports={},assets={image=function(_,path)
  check(path:find('fly_map_',1,true)~=nil,'map image loaded')
  return {setFilter=function()end}
end},content={screens={register=function(_,id,screen)
  check(registered[id]==nil,'register may not collide with an existing owner')
  registered[id]=screen
end,override=function(_,id,screen)
  check(id=='TownMap'and registered[id]==originalTownMap,
    'explicitly replace the existing TownMap owner')
  registered[id]=screen
end}},
  hooks={wrap=function(_,id,fn)
    check(id=='ui.start_menu.items','start menu seam')
    startHook=fn
  end}}
function mod.find(id)
  if id=='VOXEL_ASCENDANT'then
    return {exports={capabilities={voxelWorld=true}}}
  elseif id=='kanto_ascendant'then
    return {exports={language=function()return 'de'end,
      seviiExpedition=expedition}}
  end
end
dofile('companion/vasc-kanto-sevii-fly-map-widescreen/main.lua')(mod)
check(mod.exports.active and registered.TownMap,'companion registered')
local pressed,popped,flown=nil,0,nil
local game={save={visited={PALLET_TOWN=true},chartVisited={[1]=true,[2]=true},
    chartUnlocked=true},
  data={field={flyOrder={'PALLET_TOWN','SEVII_1','SEVII_2'},
    flyWarps={PALLET_TOWN={x=1,y=1},SEVII_1={x=2,y=2},SEVII_2={x=3,y=3}}},
    maps={PALLET_TOWN={id='PALLET_TOWN',index=0,outdoor=true},
      SEVII_1=maps.SEVII_1,SEVII_2=maps.SEVII_2}},
  overworld={map={id='SEVII_1'}},
  input={wasPressed=function(_,key)return pressed==key end},
  stack={pop=function()popped=popped+1 end,push=function()end}}
local function press(screen,key)pressed=key;screen:update(0);pressed=nil end
game.save.chartUnlocked=false
game.overworld.map.id='PALLET_TOWN'
local beforeArrival=registered.TownMap.new(game,{})
press(beforeArrival,'start')
check(beforeArrival.region=='kanto','Sevii chart hidden before first arrival')
local menu=startHook(function(_,items)return items end,game,{{id='SAVE'}})
check(menu[1].label=='KANTO-KARTE','start menu names Kanto before arrival')
game.save.chartUnlocked=true
game.overworld.map.id='SEVII_1'
menu=startHook(function(_,items)return items end,game,{{id='SAVE'}})
check(menu[1].label=='REGIONSKARTE','region map appears at first arrival')
local screen=registered.TownMap.new(game,{fly=true,onFly=function(id)flown=id end})
check(screen.region=='sevii'and #screen.flyTargets==0,
  'Sevii Fly remains locked before station radio')
check(screen.current==1 and screen.selected==1,'current island is marked')
press(screen,'start')
check(screen.region=='kanto' and #screen.flyTargets==0,
  'START shows Kanto but Fly remains locked from Sevii')
press(screen,'start')
check(screen.region=='sevii'and #screen.flyTargets==0,
  'START switches back to Sevii overview')
unlocked=true
game.save.visited.SEVII_1=true;game.save.visited.SEVII_2=true
screen=registered.TownMap.new(game,{fly=true,onFly=function(id)flown=id end})
check(screen.region=='sevii'and #screen.flyTargets==2,
  'charted islands appear after radio restoration')
press(screen,'start')
check(screen.region=='kanto'and #screen.flyTargets==1
  and screen.flyTargets[1].mapId=='PALLET_TOWN',
  'Kanto Fly becomes available after radio restoration')
press(screen,'start')
press(screen,'right')
check(screen.flyTargets[screen.flySelection].mapId=='SEVII_2',
  'spatial navigation selects second island')
press(screen,'a')
check(screen.zoomed and not flown,'first A zooms without flying')
press(screen,'a')
check(flown=='SEVII_2'and popped==1,'second A uses real Fly callback')
game.overworld.map.id='PALLET_TOWN'
screen=registered.TownMap.new(game,{})
check(screen.region=='kanto'and screen.fly==false,'ordinary Kanto map preserved')
press(screen,'start')
check(screen.region=='sevii'and #screen.locations==7,
  'ordinary map switches to seven-island overview')
check(screen:uiSize()==576,'widescreen map retained')
print('PASS Sevii fly map: '..checks..' checks')
