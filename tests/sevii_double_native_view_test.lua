-- The partner overlay must not inherit a caller's shader/clip or leak state.
local graphics={shader='caller-shader',scissor={2,3,40,30},blend='multiply'}
local stack={}
local calls=0
function graphics.push(kind)
  stack[#stack+1]={kind=kind,shader=graphics.shader,
    scissor=graphics.scissor and {unpack(graphics.scissor)},blend=graphics.blend}
end
function graphics.pop()
  local state=assert(table.remove(stack))
  graphics.shader,graphics.scissor,graphics.blend=state.shader,state.scissor,state.blend
end
function graphics.setShader(shader)graphics.shader=shader end
function graphics.setScissor(...)graphics.scissor=select('#',...)>0 and {...}or nil end
function graphics.getScissor()if graphics.scissor then return unpack(graphics.scissor)end end
function graphics.setBlendMode(mode)graphics.blend=mode end
function graphics.setColor()end
function graphics.rectangle()calls=calls+1 end
function graphics.translate()end
function graphics.scale()end
love={graphics=graphics}
local function clean()
  assert(graphics.shader==nil and graphics.scissor==nil and graphics.blend=='alpha',
    'partner overlay inherited caller paint state')
end
package.loaded['src.render.Font']={
  split=function(text)
    local spans={};for i=1,#text do spans[i]={to=i}end;return spans
  end,
  spansFitting=function(spans)return #spans end,
  drawBox=function()clean();calls=calls+1 end,
  draw=function()clean();calls=calls+1 end,
  drawCode=function()clean();calls=calls+1 end,
}
local V=dofile('sevii_double_native_view.lua')
local function battler(name)
  return {name=name,mon={hp=30,stats={hp=40}},shownHP=30,sprite=true}
end
local battle
battle={enemy=battler('FOE'),enemy2=battler('FOE2'),
  player=battler('ALLY'),player2=battler('ALLY2'),
  phase='doubleTarget',doubleTargetIndex=2,
  drawPicsLayer=function(self)
    assert(self.enemy==battle.enemy2 or self.player==battle.player2)
  end}
local function baseDraw()graphics.setShader('base-shader');graphics.setScissor(2,3,40,30)end
local function check(mode)
  battle.voxelAscendantShot=mode and {layoutContext={mode=mode}} or nil
  local before=calls
  V.draw(battle,baseDraw)
  assert(calls>before,'partner UI was not drawn')
  assert(graphics.shader=='base-shader' and graphics.scissor[1]==2
    and graphics.blend=='multiply' and #stack==0,'caller state leaked')
end
check('MAP');check('DISCS');check('ARENA');check('TERRARIUM');check(nil)
print('PASS Sevii partner overlay isolates shader, clip and blend in all modes')
