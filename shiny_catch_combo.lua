-- Catch Combo policy for the optional shiny Card. Only captured wild Pokemon
-- advance it; walking, changing maps, battles and player retreats preserve it.
return function()
  local C={}
  function C.normalize(raw)
    local species=type(raw)=='table'and raw.species or nil
    local count=type(raw)=='table'and tonumber(raw.count)or 0
    count=math.max(0,math.min(999,math.floor(count or 0)))
    if type(species)~='string'or species==''or count==0 then
      return {species=nil,count=0}
    end
    return {species=species,count=count}
  end
  function C.catch(raw,species)
    local current=C.normalize(raw)
    if type(species)~='string'or species==''then return current end
    if current.species==species then
      return {species=species,count=math.min(999,current.count+1)}
    end
    return {species=species,count=1}
  end
  function C.breakCombo()return {species=nil,count=0}end
  function C.bonusRolls(raw,species)
    local current=C.normalize(raw)
    if current.species~=species then return 0 end
    if current.count>=31 then return 6 end
    if current.count>=21 then return 3 end
    if current.count>=11 then return 1 end
    return 0
  end
  return C
end
