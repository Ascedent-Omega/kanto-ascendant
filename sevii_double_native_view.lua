-- Native 2D presentation for the narrowly opted-in Sevii trainer doubles.
-- WideBattle still owns the original field, palette, animation and menus;
-- this layer adds the two partner bodies and an explicit target picker.
local V={}
local Font=require('src.render.Font')
local function alive(b)return b and b.mon and b.mon.hp>0 and not b.fainted end
local function fitName(value,pixels)
  local name=tostring(value or '')
  local spans=Font.split(name)
  local count=Font.spansFitting(spans,pixels)
  if count>=#spans then return name end
  if count<1 then return '' end
  return name:sub(1,spans[count].to)
end
local function panel(b,x,y)
  if not alive(b)then return end
  local g=love.graphics
  g.setColor(1,1,1,1)
  Font.drawBox(math.floor(x/8),math.floor(y/8),11,3)
  g.setColor(0,0,0,1)
  local name=b.name or b.mon.species
  Font.draw(fitName(name,72),x+7,y+5)
  local maximum=math.max(1,b.mon.stats and b.mon.stats.hp or 1)
  local ratio=math.max(0,math.min(1,(b.shownHP or b.mon.hp)/maximum))
  g.setColor(.14,.14,.14,1);g.rectangle('fill',x+7,y+17,70,3)
  g.setColor(ratio>.5 and .12 or ratio>.2 and .7 or .85,
    ratio>.5 and .57 or ratio>.2 and .5 or .15,.13,1)
  g.rectangle('fill',x+7,y+17,math.floor(70*ratio+.5),3)
  g.setColor(1,1,1,1)
end
local function stagedPanel(b,x,y,enemy,width)
  if not alive(b)then return end
  local g=love.graphics
  width=width or 73
  g.setColor(.9,.94,.96,.82)
  g.rectangle('fill',x,y,width,17,2,2)
  g.setColor(enemy and .83 or .18,enemy and .21 or .66,.24,.95)
  g.rectangle('line',x+.5,y+.5,width-1,16,2,2)
  g.setColor(1,1,1,1)
  Font.draw(fitName(b.name or b.mon.species,width-6),x+3,y+2)
  local maximum=math.max(1,b.mon.stats and b.mon.stats.hp or 1)
  local ratio=math.max(0,math.min(1,(b.shownHP or b.mon.hp)/maximum))
  g.setColor(.16,.18,.20,.95);g.rectangle('fill',x+3,y+12,width-6,3)
  g.setColor(ratio>.5 and .14 or ratio>.2 and .8 or .9,
    ratio>.5 and .82 or ratio>.2 and .64 or .18,.15,1)
  g.rectangle('fill',x+3,y+12,math.floor((width-6)*ratio+.5),3)
  g.setColor(1,1,1,1)
end
local function partnerPic(battle,side,x,y,scale,clip)
  local partner=battle[side..'2']
  if not alive(partner) or not partner.sprite then return end
  local g=love.graphics
  local old=g.getScissor and {g.getScissor()} or nil
  local lead=battle[side]
  local previous=battle.wideRegion
  g.setScissor(clip[1],clip[2],clip[3],clip[4])
  g.push();g.translate(x,y);g.scale(scale)
  battle[side]=partner;battle.wideRegion=true
  local ok,err=pcall(battle.drawPicsLayer,battle,0,0,0,side,true)
  battle[side]=lead;battle.wideRegion=previous
  g.pop()
  if old and old[1] then g.setScissor(unpack(old))else g.setScissor()end
  if not ok then error(err,0)end
end
local function targetPicker(battle,staged)
  if battle.phase~='doubleTarget'then return end
  local g=love.graphics
  g.setColor(1,1,1,1)
  Font.drawBox(0,13,staged and 20 or 38,5)
  g.setColor(0,0,0,1)
  Font.draw(V.translate and V.translate('TARGET','ZIEL') or 'TARGET',8,112)
  for index=1,2 do
    local foe=battle[index==1 and'enemy'or'enemy2']
    if alive(foe)then
      local x=staged and 82 or index==1 and 84 or 196
      local y=staged and (index==1 and 112 or 128) or 120
      Font.draw(fitName(foe.name or foe.mon.species,72),x,y)
      if battle.doubleTargetIndex==index then Font.drawCode(0xED,x-9,y)end
    end
  end
end
function V.draw(battle,baseDraw)
  baseDraw(battle)
  if battle.blankForAskName then return end
  local g=love.graphics
  -- The base scene or a companion may leave a shader/scissor selected while
  -- copying the battle canvas. Draw only our extra layer with clean paint
  -- state, and give the caller its complete state back even on an error.
  g.push('all')
  local ok,err=pcall(function()
    g.setShader();g.setScissor();g.setBlendMode('alpha')
    g.setColor(1,1,1,1)
    if battle.voxelAscendantShot then
      local context=battle.voxelAscendantShot.layoutContext
      local mode=context and context.mode
      if mode=='DISCS'or mode=='TERRARIUM'then
        stagedPanel(battle.enemy2,50,3,true,60)
        stagedPanel(battle.player2,50,21,false,60)
      else
        stagedPanel(battle.enemy2,2,3,true)
        stagedPanel(battle.player2,85,3,false)
      end
      targetPicker(battle,true)
    else
      -- Separate clipped fields preserve native sprite pixels and effects.
      -- The lead pictures remain exactly where WideBattle put them.
      partnerPic(battle,'enemy',95,20,.85,{145,15,80,65})
      partnerPic(battle,'player',82,10,.85,{82,35,78,65})
      panel(battle.enemy2,0,36)
      panel(battle.player2,140,0)
      targetPicker(battle,false)
    end
  end)
  g.pop()
  if not ok then error(err,0)end
end
return V
