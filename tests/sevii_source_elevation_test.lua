local wrap
local mod={hooks={wrap=function(_,name,fn)assert(name=='movement.collision');wrap=fn end}}
local def={width=2,height=1,kaOwner='kasc.sevii-expedition/v1',kaSeviiElevations={'$&!0','$&!0'}}
local E=dofile('sevii_source_elevation.lua')(mod,{TEST=def})
local map={id='TEST',def=def}
local function call(a,b,allowed,foreign)
 local ctx={map=foreign or map,fromX=a,fromY=0,toX=b,toY=0,reason='entity'}
 local result=wrap(function(v)return v end,allowed~=false,ctx)
 return result,ctx.reason
end
assert(not call(0,1),'3 -> 5 movement layer crossed')
assert(not call(1,0),'5 -> 3 movement layer crossed')
assert(call(0,2)and call(2,1),'transparent stair mouth blocked')
assert(call(0,3),'destination layer 15 blocked')
assert(E.allow(true,{map=map,fromX=1,fromY=0,toX=0,toY=0,mover={surfing=true}}),'Surf landing on layer 3 blocked')
map.warpAtCell=function(_,x)return x==1 end
assert(call(0,1),'admitted directional stair warp blocked')
assert(not call(0,1,false),'warp reopened existing collision')
map.warpAtCell=nil
assert(not call(0,2,false),'existing collision reopened')
local allowed,reason=call(0,1);assert(not allowed and reason=='sevii-elevation')
assert(call(0,1,true,{id='TEST',def={kaOwner='foreign'}}),'foreign owner affected')
assert(call(0,1,true,{id='KANTO',def={}}),'Kanto affected')
assert(E.at(map,-1,0)==nil and E.at(map,0,2)==nil and E.at(map,.5,0)==nil)
local calls=0;local OW={crossConnection=function()calls=calls+1;return true end}
local previous=package.loaded['src.world.OverworldController'];package.loaded['src.world.OverworldController']=OW
E.install();local wrapped=OW.crossConnection;E.install();assert(OW.crossConnection==wrapped,'seam wrapper installed twice')
def.id='TEST'
local ow={map=map,player={cellX=0,cellY=0},connectionLanding=function()return def,nil,1,0 end}
assert(not OW.crossConnection(ow,'right',{})and calls==0,'unequal seam layers crossed')
ow.connectionLanding=function()return def,nil,2,0 end
assert(OW.crossConnection(ow,'right',{})and calls==1,'transparent seam blocked')
ow.map={id='KANTO',def={}}
assert(OW.crossConnection(ow,'right',{})and calls==2,'Kanto seam behavior changed')
package.loaded['src.world.OverworldController']=previous
assert(not pcall(dofile('sevii_source_elevation.lua'),mod,{BROKEN={width=2,height=1,kaOwner=def.kaOwner}}),'missing metadata accepted')
assert(not pcall(dofile('sevii_source_elevation.lua'),mod,{BROKEN={width=2,height=1,kaOwner=def.kaOwner,kaSeviiElevations={'$&','!0'}}}),'short rows accepted')
-- The continuous driver performs its own setup, so Q.K may be unset.
local fakeGame={data={field={}},mods={exports={kanto_ascendant={seviiExpedition={sourceElevation=E}}}}}
local getenv=os.getenv;os.getenv=function(name)if name=='HABITAT_QA_ROOT'then return '.'end;return getenv(name)end
local Q=dofile('tests/habitat_playthrough/drivers/common.lua')(fakeGame)
os.getenv=getenv
map.isWalkableCell=function()return true end;map.isWaterCell=function()return false end;map.cellTile=function()return 1 end
assert(Q.K==nil and not Q.pairClear(map,0,0,1,0),'uninitialized journey helper planned through source cliff')
assert(Q.pairClear(map,0,0,2,0),'uninitialized journey helper blocked transparent mouth')
print('PASS original movement elevations: unequal layers block, 0/15 destination exceptions, existing collision and foreign/Kanto ownership preserved, strict metadata; uninitialized journey helper respects source cliff')
