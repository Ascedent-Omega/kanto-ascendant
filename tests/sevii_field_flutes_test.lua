local root=assert(os.getenv('KASC_ENGINE'));package.path=root..'/?.lua;'..package.path
local Encounter=require('src.world.Encounter');local events,hooks={},{}
package.loaded['src.core.Sound']={play=function()end}
local profile={activeEpoch=3,extensionsEnabled=true}
local F=dofile('sevii_field_flutes.lua')({id='kanto_ascendant',
 content={items={get=function()return{}end,patch=function()end}},
 exports={pokemonEquipment67={held=function(mon)return mon.item end}},
 events={on=function(_,id,fn)events[id]=fn end},hooks={wrap=function(_,id,fn)hooks[id]=fn end}},
 {i18n={text=function(en)return en end},rules={peek=function()return profile end}})
local g={save={player={map='ISLAND_A'}},data={items={CLEANSE_TAG={kascSeviiFieldItem=F.OWNER}},maps={ISLAND_A={kaSeviiSource='Island'},
 ISLAND_B={kaSeviiSource='Island'},ISLAND_C={kaSeviiSource='Cave'}}},overworld={map={id='ISLAND_A'}}}
events['game.ready']{game=g}
local n=0;local function check(v,msg)n=n+1;assert(v,msg)end
local function use(id,battle)return F.use{itemId=id,save=g.save,data=g.data,overworld=g.overworld,battle=battle}end
local def={grass={rate=64,slots={{species='PIDGEY',level=5}},buckets={256}},water={rate=44}}
local ctx={mapId='ISLAND_A',terrain='grass'}
local function hits()
 local hits,calls=0,0
 for roll=0,255 do
  ctx.rng=function(a,b)check(a==0 and b==255,'native RNG range');calls=calls+1;return roll end
  if hooks['encounter.roll'](function(d,c)return Encounter.roll(d,c.rng)end,def,ctx)then hits=hits+1 end
 end
 return hits,calls
end
check(F.adjust(g,def,ctx)==def,'no flute keeps original definition')
local h,c=hits();check(h==64 and c==256+64,'baseline native rate and slot draws')
check(use('BLACK_FLUTE')=='kept','reusable field effect')
h,c=hits();check(h==32 and c==256+32,'black halves native probability without extra draws')
local adjusted=F.adjust(g,def,ctx)
check(def.grass.rate==64 and adjusted.grass.slots==def.grass.slots and adjusted.water==def.water,'original tables/slot identities unchanged')
check(use('WHITE_FLUTE')=='kept'and F.state(g).item=='WHITE_FLUTE','opposite flute replaces rather than stacks')
h,c=hits();check(h==96 and c==256+96,'white adds half of ordinary rate')
check(use('WHITE_FLUTE')=='kept'and not F.state(g),'reuse stops the field effect')
use('BLACK_FLUTE');events['map.entered']{mapId='ISLAND_B'}
check(F.state(g)and F.adjust(g,def,{mapId='ISLAND_B',terrain='grass'}).grass.rate==32,'split fragments retain one area')
events['map.entered']{mapId='ISLAND_C'}
check(not F.state(g),'different cave/interior area ends effect')
events['map.entered']{mapId='ISLAND_A'};check(not F.state(g),'returning does not reactivate expired effect')
use('WHITE_FLUTE');g.overworld.map.id='ISLAND_C';events['save.loaded']{game=g}
check(F.state(g)~=nil,'adopted save location wins over stale overworld on load')
g.overworld.map.id='ISLAND_A'
for _,terrain in ipairs{'water','indoor','grass'}do
 check(F.adjust(g,def,{mapId='ISLAND_A',terrain=terrain}).grass.rate==96,'ordinary surface '..terrain)
end
for _,terrain in ipairs{'fishing','eon_outdoor','rock_smash'}do
 check(F.adjust(g,def,{mapId='ISLAND_A',terrain=terrain})==def,'separate encounter contract '..terrain)
end
check(F.adjust(g,def,{mapId='ISLAND_A',terrain='grass',kind='land'})==def,'Gen2 after-rate contract excluded')
check(F.adjust(g,def,{mapId='ELSEWHERE',terrain='grass'})==def,'no effect in another area')
profile.activeEpoch=2;check(F.adjust(g,def,ctx)==def,'Gen2 profile no field multiplier');profile.activeEpoch=3
profile.extensionsEnabled=false;check(F.adjust(g,def,ctx)==def,'disabled generation extension respected');profile.extensionsEnabled=true
for _,rate in ipairs{0,-1,257}do local d={grass={rate=rate}};check(F.adjust(g,d,ctx)==d,'zero or invalid rate not made active')end
check(F.adjust(g,{grass={rate=200}},ctx).grass.rate==256,'saturation respects native byte comparison')
check(use('BLACK_FLUTE',{})=='failed'and F.state(g).item=='WHITE_FLUTE','battle cannot change field effect')
local lead={species='PIDGEY',item='CLEANSE_TAG'};g.save.party={lead}
check(F.supportsItem(g,'CLEANSE_TAG',3),'Cleanse Tag equipment is supported')
check(not F.supportsItem(g,'QUICK_CLAW',3),'unrelated held item excluded')
check(F.adjust(g,{grass={rate=60}},ctx).grass.rate==60,'white flute and Cleanse Tag combine once')
use('WHITE_FLUTE')
check(F.adjust(g,{grass={rate=60}},ctx).grass.rate==40,'lead Cleanse Tag lowers ordinary rate by a third')
lead.isEgg=true;check(F.adjust(g,def,ctx)==def,'egg cannot lead with a Cleanse Tag');lead.isEgg=nil
lead.item='NO_ITEM';check(F.adjust(g,def,ctx)==def,'unequipped tag has no effect');lead.item='CLEANSE_TAG'
profile.activeEpoch=1;check(F.adjust(g,def,ctx)==def,'Gen 1 cannot activate Cleanse Tag');profile.activeEpoch=2
check(F.adjust(g,{grass={rate=60}},ctx).grass.rate==40,'Gen 2 enables Cleanse Tag without flute')
profile.activeEpoch=3;profile.extensionsEnabled=false
check(F.adjust(g,def,ctx)==def,'disabled extensions suppress Cleanse Tag');profile.extensionsEnabled=true
g.save.party={};check(F.adjust(g,def,ctx)==def,'empty team has no Cleanse Tag')
use('WHITE_FLUTE')
local old=g.save;g.save={player={map='ISLAND_A'}};events['save.loaded']{game=g}
check(F.adjust(g,def,ctx)==def and not F.state(g),'new save does not inherit former state')
g.save=old;events['save.loaded']{game=g};check(F.state(g).item=='WHITE_FLUTE','old save resumes own stored mode')
-- The real outer roaming hooks are tested in the native field-flute driver.
print('PASS Sevii field flutes: '..n..' checks')
