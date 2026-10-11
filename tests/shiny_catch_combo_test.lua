local C=dofile('shiny_catch_combo.lua')()
local n=0;local function check(value,why)n=n+1;assert(value,why)end
local combo=C.normalize(nil)
check(combo.count==0 and combo.species==nil,'old saves begin without a combo')
for i=1,31 do combo=C.catch(combo,'PIKACHU')
  local expected=i>=31 and 6 or i>=21 and 3 or i>=11 and 1 or 0
  check(combo.count==i and C.bonusRolls(combo,'PIKACHU')==expected,
    'same-species catch and threshold '..i)
  check(C.bonusRolls(combo,'EEVEE')==0,'bonus belongs only to chained species '..i)
end
combo=C.catch(combo,'EEVEE')
check(combo.species=='EEVEE'and combo.count==1,'catching a different species begins its own chain')
combo=C.breakCombo()
check(combo.count==0 and combo.species==nil,'wild escape ends the combo')
check(C.normalize({species='PIKACHU',count=-7}).count==0,
  'invalid old state cannot grant extra rolls')
print('PASS Shiny Catch Combo: '..n..' checks')
