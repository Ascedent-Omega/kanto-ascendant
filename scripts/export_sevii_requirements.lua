-- Source-driven requirements, not an assertion of live catchability.
-- Run from the KASC root with KASC_ENGINE pointing at the native Lua modules.
package.path=assert(os.getenv('KASC_ENGINE'))..'/?.lua;'..package.path
local Json=require('src.link.Json')
local A=dofile('hoenn_acquisition_67_data.lua')
local H=dofile('hoenn_species_67_data.lua')
local C=dofile('backend_national_catalog_67_data.lua')
local families={};local covered={}
for _,row in ipairs(A.traceFamilies)do
  families[row.id]=row
  for _,species in ipairs(row.members)do covered[species]=row.id end
end
local result={schema='kasc.sevii-requirements/v1',
  notice='Requirements only. Registration or this manifest does not prove catchability.',
  characters={},ordinary={},special={},exceptions={{dex=487,id='GIRATINA',reason='Recurring non-catchable Distortion World antagonist'}},
  source={acquisition='hoenn_acquisition_67_data.lua',catalog='backend_national_catalog_67_data.lua',
    hoennSourceCommit=H._meta.gameDataCommit}}
local rootCount=0;for _ in pairs(families)do rootCount=rootCount+1 end
assert(rootCount==62,'character-family source changed; review the requirements')
for _,character in ipairs{'RED','GREEN','BLUE'}do
  local own={};for _,root in ipairs(A.characterPacks[character])do own[root]=true end
  local missing,members={},{}
  for root,row in pairs(families)do if not own[root]then
    missing[#missing+1]=root
    for _,species in ipairs(row.members)do members[#members+1]=species end
  end end
  table.sort(missing);table.sort(members)
  result.characters[character]={wandererFamilies=#A.characterPacks[character],missingFamilies=missing,missingSpecies=members}
end
local special={};for _,dex in ipairs{377,378,379,380,381,382,383,384,385,386,480,481,482,483,484,485,486,488,489,490,491,492,493}do special[dex]=true end
for dex=252,493 do if dex~=487 then
  local row=assert(C.entries['dex:'..dex]);local id=row.identifier:upper():gsub('[^A-Z0-9]','_')
  local item={dex=dex,key=row.key,id=id,names=row.names,generation=row.originGeneration,types=row.types}
  if special[dex]then
    item.requirement='Review existing unique catch owner; never add a second guaranteed catch'
    result.special[#result.special+1]=item
  else
    item.family=covered[id]
    item.requirement=row.originGeneration==4 and 'Gen-4 island habitat' or covered[id]and 'Close character-specific Wanderer gap' or 'Additional ordinary Hoenn acquisition, including starters and Shedinja'
    result.ordinary[#result.ordinary+1]=item
  end
end end
assert(#result.ordinary==218 and #result.special==23,'species scope changed')
local f=assert(io.open('SEVII_SPECIES_REQUIREMENTS.json','wb'));f:write(Json.encode(result),'\n');f:close()
for _,c in ipairs{'RED','GREEN','BLUE'}do local r=result.characters[c];print(c,'missing families',#r.missingFamilies,'missing species',#r.missingSpecies)end
print('Requirements:',#result.ordinary,'ordinary species;',#result.special,'unique encounters to review; Giratina never catchable')
