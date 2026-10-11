local legacy=false
local L=dofile('sevii_level_scaling.lua')({maps={KA_SEVII_ONE={}}},{
  legacyJourney={isActive=function()return legacy end}})
local game={data={pokemon={A={},B={},C={}}},save={party={
  {species='A',level=70},{species='B',level=70},{species='C',level=70}}},
  overworld={map={id='KA_SEVII_ONE'}}}
local n=0;local function check(ok,why)n=n+1;assert(ok,why)end
check(L.reference(game)==70,'whole usable team reference')
check(L.wild(game,48)==60 and L.trainer(game,62,false)==70
  and L.trainer(game,64,true)==72 and L.legend(game,65)==72,
  'ordinary, trainer, ace and legendary targets')
check(L.legend(game,80)==80 and L.trainer(game,75,false)==75,
  'authored minima are never lowered')
game.save.party={{species='A',level=100},{species='B',level=5},{species='C',level=5}}
check(L.reference(game)==92 and L.legend(game,65)==94,
  'one strong partner cannot be hidden behind weak utility members')
game.save.party={{species='A',level=100},{species='B',level=100},{species='C',level=100}}
check(L.wild(game,48)==90 and L.legend(game,80)==100
  and L.trainer(game,70,true)==100,'all targets respect level 100')
game.overworld.map.id='VERMILION_CITY'
check(L.wild(game,48)==48 and L.legend(game,65)==65,
  'Kanto and original legend levels stay unchanged')
game.overworld.map.id='KA_SEVII_ONE'
game.save.party={{species='A',level=70,isEgg=true},{species='B',level=50},
  {species='C',level=90,hp=0},{species='UNKNOWN',level=100}}
check(L.reference(game)==82,'eggs and unknown species excluded; fainted team members counted')
game.save.party={{species='A',level=1,isEgg=true}}
check(L.reference(game)==nil and L.legend(game,65)==65,
  'missing usable reference leaves the authored level')
legacy=true
game.save.party={{species='A',level=12},{species='B',level=12}}
check(L.wild(game,60)==9 and L.trainer(game,62,false)==14
  and L.trainer(game,64,true)==16 and L.legend(game,65)==20,
  'early Legacy island targets follow the active team downward')
game.save.party={{species='A',level=98}}
check(L.wild(game,48)==95 and L.trainer(game,62,false)==100
  and L.legend(game,65)==100,'Legacy upper scaling caps at level 100')
game.overworld.map.id='VERMILION_CITY'
check(L.trainer(game,62,false)==62,'Legacy scaling never changes Kanto')
print('PASS Sevii level scaling: '..n..' checks')
