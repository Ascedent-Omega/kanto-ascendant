local S=assert(loadfile('wilds_spawn_safety.lua'))()({})
local beaten={save={flags={EVENT_GOT_STARTER=true}}}
for _,id in ipairs{
  'KA_SEVII_CENTER',
  'KA_SEVII_CENTER_2F',
  'KA_SEVII_TWO_ISLAND_POKEMON_CENTER_1_F',
  'KA_SEVII_SEVEN_ISLAND_POKEMON_CENTER_2_F',
  'KA_SEVII_SEVEN_ISLAND_MART',
  'KA_SEVII_FOUR_ISLAND_POKEMON_DAY_CARE',
  'KA_SEVII_FIVE_ISLAND_HOUSE1',
  'KA_SEVII_TRAINER_TOWER_1_F',
  'KA_SEVII_TRAINER_TOWER_LOBBY',
  'KA_SEVII_FIVE_ISLAND_ROCKET_WAREHOUSE',
}do
  local ok,why=S.mapAllowed(beaten,{id=id})
  assert(not ok and why=='rejected: authored Sevii room',id)
end
assert(S.mapAllowed(beaten,{id='KA_SEVII_ONE'}))
assert(S.mapAllowed(beaten,{id='KA_SEVII_FOUR_ISLAND_ICEFALL_CAVE_1_F'}))
assert(S.mapAllowed(beaten,{id='VERMILION_POKECENTER'}))
local J=dofile('starter_habitat_json.lua')
local file=assert(io.open('assets/sevii_local/bundle.json','r'))
local bundle=J.decode(file:read('*a'));file:close()
local blocked=0
for _,map in ipairs(bundle.maps)do
  local ok=S.mapAllowed(beaten,map.id)
  if not ok then
    assert(not map.outdoor,'blocked a Sevii outdoor map: '..map.id)
    blocked=blocked+1
  end
end
assert(blocked==52,'not every authored Sevii room is protected: '..blocked)
print('PASS all 52 Sevii rooms exclude ambient Wilds; caves, outdoors and Kanto retain spawns')
