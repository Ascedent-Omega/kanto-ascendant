local owned={kaSeviiSource='RubyPath',tileset='KA_CAVE',width=8,height=8,kaSeviiIsland=1}
local S={maps={SEVII=owned}};local event,info,warnings
local mod={events={on=function(_,name,callback)assert(name=='battle.started');event=callback end},
 log={info=function(_,message)info=message end,warn=function(_,message)warnings=message end}}
local M=dofile('sevii_battle_animations.lua')(mod,S)
local checks=0;local function check(v,message)checks=checks+1;assert(v,message)end
local native={};for _,donor in pairs(M.aliases)do native[donor]={seq={}}end
local function fixture(map,def)
 local calls={};local start=function(self,id,side,options)calls[#calls+1]={id=id,side=side,options=options};return 'native',id end
 local player={data={moveAnims=native},start=start}
 return {game={overworld={map={id=map,def=def}}},animPlayer=player},calls,start
end
local battle,calls=fixture('SEVII',owned);event{battle=battle}
check(battle.animPlayer._kascSeviiAnimations==M.OWNER,'owned battle binds')
local originalData=battle.animPlayer.data;local total=0
for id,donor in pairs(M.aliases)do
 total=total+1;info=nil;local opts={ball='MASTER_BALL'}
 local value,result=battle.animPlayer:start(id,false,opts)
 check(value=='native'and result==donor,'native return preserved '..id)
 check(calls[#calls].side==false and calls[#calls].options==opts,'side/options retained '..id)
 check(info and info:find('map=SEVII',1,true)and info:find('move='..id,1,true),'mapping logged '..id)
 check(battle.animPlayer.data==originalData and native[id]==nil,'shared data unchanged '..id)
end
check(total==19,'complete audited gap set')
local composite,childCalls=fixture('SEVII',owned)
local child=composite.animPlayer
local outerStart=function(self,id,side,options)return self.native:start(id,side,options)end
composite.animPlayer={native=child,start=outerStart,holder={registry={programs={SYNTHESIS={}}}}}
check(M.bind(composite),'VASC native child binds')
composite.animPlayer:start('SYNTHESIS',false)
check(childCalls[1].id=='RECOVER','VASC native child compiles reviewed donor')
check(composite.animPlayer.start==outerStart and composite.animPlayer.holder.registry.programs.SYNTHESIS~=nil,
 'custom move id, targeting and registry retain their owner')
local soundBattle=fixture('SEVII',owned)
local borrowed,borrowedCalls=fixture('SEVII',owned)
local originalBattleStart=soundBattle.animPlayer.start
check(M.bind(soundBattle,borrowed.animPlayer),'sound preparation binds its borrowed player')
borrowed.animPlayer:start('SYNTHESIS',true)
check(borrowedCalls[1].id=='RECOVER','sound preparation compiles reviewed recovery rows')
check(soundBattle.animPlayer.start==originalBattleStart and not soundBattle.animPlayer._kascSeviiAnimations,
 'borrowed sound binding leaves actual battle player untouched')
local nativeKanto=fixture('PALLET_TOWN',owned);local untouched=fixture('SEVII',owned)
local untouchedStart=untouched.animPlayer.start
check(not M.bind(nativeKanto,untouched.animPlayer)and untouched.animPlayer.start==untouchedStart,
 'Kanto sound preparation keeps its existing native source')
local installed=battle.animPlayer.start
check(not M.bind(battle)and installed==battle.animPlayer.start,'idempotent binding')
native.SYNTHESIS={seq={'authored'}};info=nil;battle.animPlayer:start('SYNTHESIS',true)
check(calls[#calls].id=='SYNTHESIS'and info==nil,'authored animation takes precedence');native.SYNTHESIS=nil
warnings=nil;battle.animPlayer:start('UNREVIEWED',true)
check(calls[#calls].id=='UNREVIEWED'and warnings and warnings:find('map=SEVII',1,true),'unreviewed gap stays explicit')
for _,id in ipairs{'PALLET_TOWN','MT_MOON_1F','VIRIDIAN_FOREST','VIRIDIAN_POKECENTER'}do
 local b,c,start=fixture(id,owned);event{battle=b};b.animPlayer:start('SYNTHESIS',true)
 check(b.animPlayer.start==start and c[1].id=='SYNTHESIS','Kanto original animation '..id)
end
local foreign={kaSeviiSource='RubyPath',tileset='FOREIGN',width=8,height=8,kaSeviiIsland=1}
local b,c,start=fixture('SEVII',foreign)
check(not M.bind(b)and b.animPlayer.start==start,'foreign map cannot acquire ownership')
local missing,c=fixture('SEVII',owned);native.THUNDER=nil;warnings=nil
check(M.bind(missing),'missing donor battle binds');missing.animPlayer:start('ZAP_CANNON',true)
check(c[1].id=='ZAP_CANNON'and warnings and warnings:find('native=THUNDER',1,true),'missing donor reported, never fabricated')
print('Sevii battle animations: '..checks..' checks passed')
