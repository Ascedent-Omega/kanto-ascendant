local open,enabled=true,true
local maps={PALLET_TOWN={index=0,tileset='OVERWORLD'},MT_MOON_1F={index=59,tileset='CAVERN'},
 VIRIDIAN_FOREST={index=51,tileset='FOREST'},CELADON_MART_ROOF={index=122,tileset='MART'},
 CELADON_MANSION_ROOF_HOUSE={index=130,tileset='HOUSE'},
 KA_BLAINE_VOLCANO_FOOT={index=1997,outdoor=true,tileset='CAVERN'},
 KA_HEVO_RAYQUAZA_CHAMBER={index=1986,outdoor=true,tileset='SKY'}}
local S={maps={},habitats={},specialEncounters={storyReady=function()return open end},
 chapters={journal=function()return ''end},state=function()return{}end,assetsReady=function()return true end}
local R={setExpansion=function()end,available=function()return enabled end,
 acceptsExpansionEncounter=function(_,r)return r.live==true end}
local V=dofile('sevii_eon_roaming.lua')({content={maps={each=function()return pairs(maps)end,get=function(_,id)return maps[id]end}},hooks={wrap=function()end}},S,{hoennRoamers=R})
local checks=0;local function check(v,msg)checks=checks+1;assert(v,msg)end
local policy={firstIndoorMap=37,excludedTileset='FOREST',custom='preserved'}
local g={data={field={indoorEncounters=policy}}}
local baseRoll=function(self,definition,terrain)
 self.observed={definition=definition,terrain=terrain,policy=g.data.field.indoorEncounters}
 return self.answer
end
local ow={map={id='PALLET_TOWN',def=maps.PALLET_TOWN},answer={live=true},rollEncounter=baseRoll}
g.overworld=ow
ow.onStepComplete=function(self)
 self.enteredPolicy=g.data.field.indoorEncounters
 if self.abort then return 'early-return'end
 if self.throw then error('host-error')end
 local p=g.data.field.indoorEncounters
 if self.map.def.index>=p.firstIndoorMap and self.map.def.tileset~=p.excludedTileset then
  return self:rollEncounter({ordinaryGrass=true},'indoor')
 end
end
V.install(g);local wrapped=ow.onStepComplete;V.install(g)
check(wrapped==ow.onStepComplete,'reinstall does not stack wrappers')
check(ow:onStepComplete()==ow.answer,'new outdoor floor admits live roaming proposal')
check(ow.observed.terrain=='eon_outdoor'and ow.observed.definition==nil,'new floor never receives ordinary grass pool')
check(ow.observed.policy.custom=='preserved'and g.data.field.indoorEncounters==policy,'exact original policy restored')
check(ow.rollEncounter==baseRoll,'exact preexisting roll method restored')
ow.answer={ordinary=true};check(not ow:onStepComplete(),'unrelated hook result cannot invent ordinary town encounters')
ow.throw=true;local ok,err=pcall(ow.onStepComplete,ow);ow.throw=nil
check(not ok and err:find('host-error',1,true),'host error remains visible')
check(g.data.field.indoorEncounters==policy and ow.rollEncounter==baseRoll,'host error also restores both scoped changes')
ow.abort=true;ow.observed=nil;check(ow:onStepComplete()=='early-return'and not ow.observed,'script/grace/warp early returns preserved');ow.abort=nil
check(g.data.field.indoorEncounters==policy,'early return restores policy')
ow.map={id='MT_MOON_1F',def=maps.MT_MOON_1F};ow.answer={ordinary=true}
check(ow:onStepComplete()==ow.answer and ow.observed.definition.ordinaryGrass,'excluded cave retains original ordinary encounter')
check(ow.enteredPolicy==policy,'cave never receives extended policy')
ow.map={id='VIRIDIAN_FOREST',def=maps.VIRIDIAN_FOREST};ow.answer={live=true}
check(ow:onStepComplete()==ow.answer and ow.observed.terrain=='eon_outdoor','forest paths also admit roaming encounter')
open=false;ow.observed=nil;check(not ow:onStepComplete()and not ow.observed and ow.enteredPolicy==policy,'story-locked forest keeps original exclusion');open=true
enabled=false;check(not ow:onStepComplete()and ow.enteredPolicy==policy,'disabled or unavailable roamer leaves host untouched');enabled=true
check(V.maps.CELADON_MART_ROOF and not V.maps.CELADON_MANSION_ROOF_HOUSE,'terrace outside, roof house inside')
check(V.accepts(g,'KA_BLAINE_VOLCANO_FOOT'),'volcano clearing is outside despite cavern art')
check(not V.accepts(g,'KA_HEVO_RAYQUAZA_CHAMBER'),'closed weather chamber never admits a roamer')
for _,id in ipairs(V.routes(g))do check(id~='KA_HEVO_RAYQUAZA_CHAMBER','closed destination cannot strand a roamer')end
local host={rollsIndoorEncounters=function(def,p)
 return not def.outdoor and def.index>=p.firstIndoorMap and def.tileset~=p.excludedTileset
end}
package.loaded['src.world.OverworldController']=host
local nativeFloor=host.rollsIndoorEncounters
local owned={index=2100,outdoor=true,tileset='KA_SEVII_TILES_TEST'}
S.maps.KA_SEVII_TEST=owned;V.maps.KA_SEVII_TEST='TestIsland'
local ow2={map={id='KA_SEVII_TEST',def=owned},rollEncounter=baseRoll,answer={live=true}}
g.overworld=ow2
ow2.onStepComplete=function(self)
 if self.abort then return 'early-return'end
 if self.throw then error('new-host-error')end
 if host.rollsIndoorEncounters(self.map.def,g.data.field.indoorEncounters)then
  return self:rollEncounter(nil,'indoor')
 end
end
V.install(g)
check(ow2:onStepComplete()==ow2.answer,'current host admits owned outdoor Sevii floor')
check(ow2.observed.terrain=='eon_outdoor','owned floor retains real roamer hook')
check(host.rollsIndoorEncounters==nativeFloor and owned.outdoor==true,'host helper and source outdoor setting restored')
ow2.throw=true;ok,err=pcall(ow2.onStepComplete,ow2);ow2.throw=nil
check(not ok and err:find('new-host-error',1,true),'current host error remains visible')
check(host.rollsIndoorEncounters==nativeFloor and g.data.field.indoorEncounters==policy,'current host error restores scoped helper and policy')
ow2.abort=true;check(ow2:onStepComplete()=='early-return','native earlier returns retained');ow2.abort=nil
ow2.map={id='PALLET_TOWN',def={index=0,outdoor=true,tileset='OVERWORLD'}};ow2.observed=nil
check(not ow2:onStepComplete()and not ow2.observed,'current Kanto outdoor exclusion is unchanged')
check(host.rollsIndoorEncounters==nativeFloor,'Kanto leaves native helper untouched')
print('PASS Sevii Eon surfaces: '..checks..' checks')
