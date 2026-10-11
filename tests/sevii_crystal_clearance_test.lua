-- Use the actual placement policy; native-capture tests cover real images.
local mod={read=function()return nil end,options={get=function()return nil end},events={on=function()end}}
local A=dofile('crystal_animation.lua')(mod,{guestDexes={[269]=true},
  classic2DConnector={enabled=function()return true end,frontOffset=function()return -8,-8 end}})
local checks=0
local function check(value,why)checks=checks+1;assert(value,why)end
local function offset(dex,width,height,source,scale)
  local mon={species='TEST'}
  local image={getDimensions=function()return width,height end}
  A.activeFrontMons[mon]={source=source or'crystal',dex=dex,requestedScale=scale}
  return A.enemyFrontOffset({enemy={mon=mon,sprite=image}})
end
for _,dex in ipairs{210,269}do
  for height=8,56 do
    local dx,dy=offset(dex,56,height)
    local top=8*(7-math.max(1,math.min(7,math.floor(height/8))))+dy
    check(dx==-8,'existing horizontal placement retained')
    check(top>=0,'no clipped head on native Crystal card')
    check(top+height<=56,'no overlap with player name')
  end
end
local _,dy=offset(800,56,56);check(dy==-8,'unregistered external species untouched')
_,dy=offset(25,56,56);check(dy==-8,'Kanto presentation untouched')
_,dy=offset(269,96,96);check(dy==-8,'large non-native assets untouched')
_,dy=offset(269,56,56,'pixel2d',1);check(dy==-4,'fitted classic card owner retains its own placement')
print('PASS Crystal front clearance: '..checks..' checks')
