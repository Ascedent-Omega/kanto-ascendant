local function copy(value)
  if type(value)~='table'then return value end
  local result={};for key,item in pairs(value)do result[key]=copy(item)end;return result
end
local saved={expeditionComplete=true}
local maps,sites,talks={},{},{}
local S={maps=maps,links={},chapters={journal=function()return'EXPEDITION'end},
  specialEncounters={storyReady=function()return true end},
  state=function()return copy(saved)end,persist=function(next) saved=copy(next)end,
  walkable=function()return true end}
function S.location(source,x,y)
  local map='KA_SEVII_'..source;maps[map]=maps[map]or{objects={}}
  S.links[map]=S.links[map]or{};return map,x,y
end
local message,menu,battles
local applied,lookups=0,0
local world={npc=function(_,map,name)
  lookups=lookups+1
  return{setPassable=function(_,value)assert(value==true);applied=applied+1 end}
end}
local ui={tr=function(en)return en end,box=function(_,text)message=text end,
  world=function()return world end,
  talks=talks,npc=function(map,name,_,__,x,y)
    maps[map].objects[#maps[map].objects+1]={name=name,x=x,y=y}
  end,menu={new=function(_,_,rows,options)menu={rows=rows,options=options,close=function()end};return menu end}}
local P={rows={RED={character='RED'},BLUE={character='BLUE'},GREEN={character='GREEN'}},LEVEL=70,
  bindSeviiSites=function(rows)sites=rows;return true end,caught=function()return false end,
  challenge=function(_,__,___,____,row)battles=row.character end}
local character='RED';local door=false;local dex=false
local journey={activeCharacter=function()return character end,currentHevoDoorVisit=function()return door end}
local D={report=function()return{portalReady=dex,foundationMissing=dex and{}or{'TREECKO'}}end}
local T=dofile('sevii_weather_trio.lua')(S,ui,{hoennLegendPortals=P,journey=journey,hoennDex=D})
local n=0;local function check(ok,why)n=n+1;assert(ok,why)end
check(T.sites==sites and sites.RED and sites.BLUE and sites.GREEN,'three island sites bound')
local game={save={},stack={push=function(_,panel)menu=panel end}}
local function talk(who)
  message=nil;menu=nil
  check(talks[sites[who].name](game,nil,nil,nil),'talk handled '..who)
end
character='BLUE';talk('RED');check(message:find('RED path',1,true),'BLUE cannot awaken RED')
talk('BLUE');check(message:find('black door',1,true),'own shrine visit required')
door=true;talk('BLUE');check(message:find('130 species',1,true),'Dex threshold required')
dex=true;talk('BLUE');check(message:find('KYOGRE is now waiting',1,true),'Dex completion triggers visible awakening')
check(saved.weatherSealAwakened.BLUE and not saved.weatherSealAwakened.RED,'event persists per character')
talk('BLUE');check(menu and menu.rows[1].value=='approach','awakened site offers encounter')
menu.options.onChoose(menu.rows[1],menu)
check(battles=='BLUE','approach delegates to canonical Hoenn encounter')
character='RED';talk('RED');check(message:find('GROUDON is now waiting',1,true),'RED has independent event')
character='GREEN';talk('GREEN');check(message:find('RAYQUAZA is now waiting',1,true),'GREEN has independent event')
check(not saved.weatherSealAwakened.YELLOW,'no foreign event')
check(S.chapters.journal():find('non-Jirachi Hoenn record',1,true),'journal preserves Jirachi door rule')
for _,who in ipairs{'RED','BLUE','GREEN'}do
  local site=sites[who];game.overworld={map={id=site.map},npcs={}}
  local before=applied;T.install(game)
  check(applied==before+1,'optional weather seal preserves route '..who)
  local calls=lookups;T.install(game)
  check(lookups==calls,'no repeated per-frame SDK handles '..who)
  game.overworld.npcs={};T.install(game)
  check(applied==before+2,'native reload/reentry reapplies route policy '..who)
  check(maps[site.map].objects[1].kaSeviiRoutePassable==true,'authored route metadata '..who)
end
game.overworld={map={id='PALLET_TOWN'},npcs={}}
local calls=lookups;T.install(game)
check(lookups==calls,'Kanto actors are untouched')
print('PASS Sevii weather trio: '..n..' checks')
