-- Native Sevii trainer doubles. Attached to one BattleState instance only;
-- ordinary Kanto battles and the base engine keep their original methods.
local M={}
local function alive(b)return b and b.mon and b.mon.hp>0 end
local function actor(b,side,index)
  return b[side..(index==2 and '2' or '')]
end
local function firstAlive(b,side)
  for index=1,2 do local a=actor(b,side,index);if alive(a)then return a end end
end
local function activeList(b,side)
  local out={}
  for index=1,2 do local a=actor(b,side,index);if alive(a)then out[#out+1]=a end end
  return out
end
local function priority(b,action)
  if not action then return 0 end
  if action.special=='playerSwitch' or action.special=='spentItem'then return 6 end
  local move=action.id and b.data.moves[action.id]
  return move and move.priority or action.id=='QUICK_ATTACK'and 1
    or action.id=='COUNTER'and -1 or 0
end
function M.canAttach(battle,game,layout)
  if not(battle and battle.kind=='trainer'and game and game.save
      and layout and battle.enemyParty and #battle.enemyParty>=2
      and battle.enemyParty[2].hp>0 and battle.player and battle.enemy
      and battle.player.mon.hp>0)then return false end
  local second
  for _,mon in ipairs(game.save.party or{})do
    if mon~=battle.player.mon and mon.hp>0 and not mon.isEgg
        and not mon.egg and not mon.eggSpecies then second=mon;break end
  end
  return second~=nil,second
end
function M.attach(battle,game,layout,view)
  local ready,second=M.canAttach(battle,game,layout)
  if not ready then return false,'not-two-ready-sides'end
  local BattleState=require('src.battle.BattleState')
  local TurnOrder=require('src.battle.TurnOrder')
  local TrainerAI=require('src.battle.TrainerAI')
  local Runtime=require('src.mods.Runtime')
  local Status=require('src.battle.Status')
  local Strings=require('src.core.Strings')
  local original={update=battle.update,resolveTurn=battle.resolveTurn,
    onFaint=battle.onFaint,enemyMonFainted=battle.enemyMonFainted,
    playerMonFainted=battle.playerMonFainted,endOfTurn=battle.endOfTurn,
    stepHPDrain=battle.stepHPDrain,updateQueue=battle.updateQueue,
    clearTurnFlinches=battle.clearTurnFlinches,
    syncShownStatus=battle.syncShownStatus,finish=battle.finish,
    draw=battle.draw}
  battle.player2=BattleState.makeBattler(battle.data,second,true,game.save)
  battle.enemy2=BattleState.makeBattler(battle.data,battle.enemyParty[2],false)
  battle.enemy2Index=2
  battle.seviiDoubleArena=layout
  battle.doubleBattle=true
  battle.doubleChoice=1
  battle.doubleCommands={}
  battle.doubleFaintPlayer={}
  battle.doubleFaintEnemy={}
  battle.wideLayout=function(self)
    -- VASC's staged renderer owns the 160px transparent battle surface.
    -- Native OFF/fallback doubles use the wider four-body 2D surface.
    return self.voxelAscendantShot==nil
  end
  if view and type(view.draw)=='function'then
    battle.draw=function(self)return view.draw(self,original.draw)end
  end
  battle.syncSides=function(self)
    self.sides[1].battlers[1],self.sides[1].battlers[2]=self.player,self.player2
    self.sides[2].battlers[1],self.sides[2].battlers[2]=self.enemy,self.enemy2
  end
  battle:syncSides()
  battle.participants=battle.participants or{}
  battle.participants[battle.player.mon]=true
  battle.participants[battle.player2.mon]=true
  if game.save.pokedex then game.save.pokedex.seen[battle.enemy2.mon.species]=true end
  battle.clearTurnFlinches=function(self)
    for _,side in ipairs{'player','enemy'}do
      for _,b in ipairs(activeList(self,side))do
        if not(b.mustRecharge or b.rageMove)then b.flinched=false end
      end
    end
  end
  battle.syncShownStatus=function(self)
    for _,side in ipairs{'player','enemy'}do
      for _,b in ipairs(activeList(self,side))do b.shownStatus=b.mon.status end
    end
  end
  battle.stepHPDrain=function(self)
    local busy=original.stepHPDrain(self)
    for _,b in ipairs{self.player2,self.enemy2}do
      if b and b.shownHP then
        local goal=b.mon.hp
        if b.drainFloor and b.drainFloor>goal and b.shownHP>=b.drainFloor then
          goal=b.drainFloor
        end
        if b.shownHP~=goal then
          local step=math.max(1,b.mon.stats.hp)/96
          b.shownHP=b.shownHP>goal and math.max(goal,b.shownHP-step)
            or math.min(goal,b.shownHP+step)
          busy=busy or b.shownHP~=goal
        end
      end
    end
    return busy
  end
  battle.updateQueue=function(self)
    local busy=original.updateQueue(self)
    if not self.draining then
      if self.player2 then self.player2.drainFloor=nil end
      if self.enemy2 then self.enemy2.drainFloor=nil end
    end
    return busy
  end
  local function enemyChoice(self,battler)
    local targets=activeList(self,'player')
    local target=targets[#targets>0 and self.rng(1,#targets) or 1]
    if not target then return nil end
    local previousEnemy,previousPlayer=self.enemy,self.player
    self.enemy,self.player=battler,target
    local ok,chosen=pcall(function()
      return self:lockedAction(battler)
        or TrainerAI.chooseMove(battler,self.rng,self)
    end)
    self.enemy,self.player=previousEnemy,previousPlayer
    if not ok then error(chosen,0)end
    return chosen,target
  end
  local function queueTurn(self)
    local actions={}
    for _,entry in ipairs(self.doubleCommands)do
      if alive(entry.battler)then actions[#actions+1]=entry end
    end
    for _,foe in ipairs(activeList(self,'enemy'))do
      local move,target=enemyChoice(self,foe)
      if move and target then actions[#actions+1]={battler=foe,action=move,target=target}end
    end
    for _,entry in ipairs(actions)do
      entry.priority=priority(self,entry.action)
      entry.speed=TurnOrder.effectiveSpeed(entry.battler)
      entry.tie=self.rng(0,65535)
    end
    table.sort(actions,function(a,b)
      if a.priority~=b.priority then return a.priority>b.priority end
      if a.speed~=b.speed then return a.speed>b.speed end
      return a.tie>b.tie
    end)
    self.turnCount=(self.turnCount or 0)+1
    Runtime.emit('battle.turn_started',{battle=self,turn=self.turnCount,
      playerAction=self.doubleCommands[1] and self.doubleCommands[1].action})
    self.phase='messages';self.afterQueue='menu';self.doubleChoice=1
    self.doubleCommands={}
    for _,entry in ipairs(actions)do
      self:act(function()
        if self.result or not alive(entry.battler)then return end
        local side=entry.battler.isPlayer and'enemy'or'player'
        local target=alive(entry.target)and entry.target or firstAlive(self,side)
        if entry.action.special=='spentItem'then return end
        if entry.action.special=='playerSwitch'then
          local slot=self.player==entry.battler and'player'or'player2'
          local previous=self[slot]
          self:restoreMimicked(previous)
          self[slot]=BattleState.makeBattler(self.data,entry.action.mon,true,game.save)
          self:syncSides()
          self.participants[self[slot].mon]=true
          Runtime.emit('battle.battler_switched',{battle=self,side=self.sides[1],
            battler=self[slot],previous=previous})
          self:sayNext(self:sendOutText(self[slot].name))
          return
        end
        if target then
          -- Existing KASC move hooks identify the acting side through
          -- battle.player / battle.enemy. Bind the actual pair only while
          -- resolving this action, then restore the four persistent slots
          -- before the next queue item or render frame.
          local leadPlayer,leadEnemy=self.player,self.enemy
          if entry.battler.isPlayer then
            self.player,self.enemy=entry.battler,target
          else
            self.player,self.enemy=target,entry.battler
          end
          local ok,err=pcall(self.executeAction,self,entry.battler,target,entry.action)
          self.player,self.enemy=leadPlayer,leadEnemy
          self:syncSides()
          if not ok then error(err,0)end
        end
      end)
    end
    self:act(function()self:endOfTurn()end)
  end
  local function commitChoice(self,action,target)
    local battler=actor(self,'player',self.doubleChoice)
    self.doubleCommands[#self.doubleCommands+1]={battler=battler,
      action=action,target=target}
    if self.doubleChoice==1 and alive(self.player2)then
      self.doubleChoice=2
      self.phase='menu'
      self.menuIndex=1
    else queueTurn(self)end
  end
  battle.resolveTurn=function(self,action)
    self.doublePendingAction=action
    self.doubleTargetIndex=1
    self.phase='doubleTarget'
  end
  battle.itemUsed=function(self,messages)
    self:syncShownStatus()
    for _,message in ipairs(messages or{})do self:say(message)end
    table.insert(self.queue,{drain=true})
    commitChoice(self,{special='spentItem'})
  end
  battle.openParty=function(self)
    local chosen=actor(self,'player',self.doubleChoice)
    self.phase='messages';self.afterQueue='menu'
    self:ui(function()
      return self:buildScreen('PartyMenu',{battle=self,onSwitch=function(mon)
        if mon==self.player.mon or self.player2 and mon==self.player2.mon then
          self:say(Strings('%s is\nalready out!',chosen.name))
        elseif mon.hp<=0 then self:say(Strings("There's no will\nto fight!"))
        else commitChoice(self,{special='playerSwitch',mon=mon})end
      end})
    end)
  end
  battle.update=function(self,dt)
    if self.phase=='doubleTarget'then
      self:tickFx()
      local input=self.game.input
      if input:wasPressed('left')or input:wasPressed('right')
          or input:wasPressed('up')or input:wasPressed('down')then
        local other=self.doubleTargetIndex==1 and 2 or 1
        if alive(actor(self,'enemy',other))then self.doubleTargetIndex=other end
      elseif input:wasPressed('b')then self.phase='moveSelect'
      elseif input:wasPressed('a')then
        local target=actor(self,'enemy',self.doubleTargetIndex)
        if alive(target)then
          local action=self.doublePendingAction
          self.doublePendingAction=nil
          commitChoice(self,action,target)
        end
      end
      return
    end
    local lead=self.player
    if self.doubleChoice==2 and alive(self.player2)
        and (self.phase=='menu'or self.phase=='moveSelect')then
      self.player=self.player2
    end
    local ok,result=pcall(original.update,self,dt)
    self.player=lead
    if not ok then error(result,0)end
    return result
  end
  battle.onFaint=function(self,battler)
    if battler.faintQueued then return end
    local queue=battler.isPlayer and self.doubleFaintPlayer or self.doubleFaintEnemy
    queue[#queue+1]=battler
    return original.onFaint(self,battler)
  end
  battle.enemyMonFainted=function(self)
    local defeated=table.remove(self.doubleFaintEnemy,1)
    if not defeated then return end
    -- A move hook can complete a faint while the acting pair is temporarily
    -- bound to the legacy lead fields. The second slot remains authoritative.
    local slot=self.enemy2==defeated and'enemy2'or'enemy'
    local originalEnemy=self.enemy
    self.enemy=defeated
    self:awardExp()
    self.enemy=originalEnemy
    for _,active in ipairs(activeList(self,'player'))do
      self.participants[active.mon]=true
    end
    local activeOther=slot=='enemy'and self.enemy2 or self.enemy
    local replacement
    for index,mon in ipairs(self.enemyParty)do
      if mon.hp>0 and (not activeOther or mon~=activeOther.mon)then
        replacement=index;break
      end
    end
    if replacement then
      self[slot]=BattleState.makeBattler(self.data,self.enemyParty[replacement],false)
      if slot=='enemy'then self.enemyIndex=replacement else self.enemy2Index=replacement end
      self:syncSides()
      if game.save.pokedex then game.save.pokedex.seen[self[slot].mon.species]=true end
      Runtime.emit('battle.battler_switched',{battle=self,side=self.sides[2],
        battler=self[slot],previous=defeated})
      self:sayNext(Strings('%s sent\nout %s!',self.trainer.name,self[slot].name))
      return
    end
    if activeOther and alive(activeOther)then
      if slot=='enemy'then
        self.enemy=activeOther;self.enemy2=defeated
        self.enemyIndex=self.enemy2Index
        self:syncSides()
        Runtime.emit('battle.battler_switched',{battle=self,side=self.sides[2],
          battler=self.enemy,previous=defeated})
      end
      return
    end
    self:syncSides()
    if not firstAlive(self,'enemy')then
      local award=self.awardExp
      self.awardExp=function()end
      local ok,err=pcall(original.enemyMonFainted,self)
      self.awardExp=award
      if not ok then error(err,0)end
    end
  end
  battle.playerMonFainted=function(self)
    local defeated=table.remove(self.doubleFaintPlayer,1)
    if not defeated then return end
    local slot=self.player2==defeated and'player2'or'player'
    local other=slot=='player'and self.player2 or self.player
    local replacement
    for _,mon in ipairs(game.save.party)do
      if mon.hp>0 and (not other or mon~=other.mon)then replacement=mon;break end
    end
    if replacement then
      self[slot]=BattleState.makeBattler(self.data,replacement,true,game.save)
      self:syncSides();self.participants[self[slot].mon]=true
      Runtime.emit('battle.battler_switched',{battle=self,side=self.sides[1],
        battler=self[slot],previous=defeated})
      self:sayNext(self:sendOutText(self[slot].name))
      return
    end
    if other and alive(other)then
      if slot=='player'then
        self.player=other;self.player2=defeated
        self:syncSides()
        Runtime.emit('battle.battler_switched',{battle=self,side=self.sides[1],
          battler=self.player,previous=defeated})
      end
      return
    end
    self:syncSides()
    if not firstAlive(self,'player')then
      local ok,err=pcall(original.playerMonFainted,self)
      if not ok then error(err,0)end
    end
  end
  battle.endOfTurn=function(self)
    if not self.result then
      for _,side in ipairs{'player','enemy'}do
        local b=self[side..'2']
        local opp=firstAlive(self,side=='player'and'enemy'or'player')
        if alive(b)and opp then
          for _,message in ipairs(Status.residual(b,opp,self))do self:sayNext(message)end
          if b.mon.hp<=0 then self:onFaint(b)end
        end
      end
    end
    return original.endOfTurn(self)
  end
  battle.finish=function(self)
    if self.player2 then self:restoreMimicked(self.player2)end
    if self.enemy2 then self:restoreMimicked(self.enemy2)end
    return original.finish(self)
  end
  return true,battle
end
return M
