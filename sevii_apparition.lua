-- A story screen, deliberately independent of all battle/species APIs.
local A={asset='assets/non_crystal_pixel_2d_67/gen2ified/front/487.png'}
function A.open(game,root,tr,done,opts)
  local finale=opts and opts.finale==true
  local path=root..'/'..A.asset
  if not love or not love.filesystem.getInfo(path)then return false,'missing-art'end
  local ok,img=pcall(love.graphics.newImage,path)
  if not ok then return false,'unreadable-art'end
  img:setFilter('nearest','nearest')
  local Font=require('src.render.Font')
  local scene={isOpaque=true,kind=finale and'sevii-local-seal'or'sevii-giratina-apparition',phase=1,age=0}
  function scene:sgbPalettes()
    return {require('src.render.PaletteFX').trueColorZone(0,0,19,17)}
  end
  local lines={
    tr('THE WALL OPENS','EIN RISS IM STEIN'),
    tr('GIRATINA','GIRATINA'),
    tr('THE SHADOW REMAINS','DER SCHATTEN BLEIBT'),
  }
  if finale then lines={tr('THREE ANCHORS','DREI ANKER'),tr('HOLD THE BOUNDARY','HALTE DIE GRENZE'),
    tr('SEVII IS SAFE','SEVII IST SICHER')}end
  function scene:update(dt)
    self.age=self.age+math.min(dt or 1/60,1/15)
    if self.age<0.6 then return end
    if game.input:wasPressed('a')or game.input:wasPressed('b')then
      if self.phase<3 then self.phase=self.phase+1;self.age=0
      else game.stack:pop();done()end
    end
  end
  function scene:draw()
    local g=love.graphics;g.push('all')
    g.setColor(0.035,0.025,0.08,1);g.rectangle('fill',0,0,160,144)
    local ringCount=finale and(self.phase==3 and 0 or 8-self.phase*2)or 7
    for i=1,ringCount do
      local pulse=math.sin(self.age*1.4+i)*2
      g.setColor(0.14+i*0.035,0.06,0.23+i*0.045,1)
      g.ellipse('line',80,65,12+i*6+pulse,10+i*5,24)
    end
    -- Floating stone fragments imply broken space without screen flashes.
    for i=1,(finale and self.phase==3 and 0 or 6)do
      local x=12+(i*29)%135;local y=24+(i*17)%76+math.sin(self.age+i)*3
      g.setColor(0.31,0.28,0.40,1);g.rectangle('fill',x,math.floor(y),7,4)
    end
    if finale then
      for _,p in ipairs{{28,88},{80,30},{132,88}}do
        g.setColor(0.25,0.7,0.8,1);g.line(p[1],p[2],80,72)
        g.setColor(0.7,0.9,1,1);g.rectangle('fill',p[1]-3,p[2]-3,7,7)
      end
      if self.phase<3 then
        local scale=self.phase==1 and 0.8 or 0.4
        g.setColor(0.30,0.13,0.37,1)
        g.draw(img,math.floor(80-img:getWidth()*scale/2),math.floor(65-img:getHeight()*scale/2),0,scale,scale)
      else
        g.setColor(0.32,0.72,0.88,1)
        for y=57,99,14 do g.line(12,y,148,y)end
      end
    elseif self.phase==2 then
      g.setColor(1,1,1,1);g.draw(img,math.floor(80-img:getWidth()/2),math.floor(65-img:getHeight()/2))
    else
      g.setColor(0.07,0.025,0.09,1);g.draw(img,math.floor(80-img:getWidth()/2),math.floor(65-img:getHeight()/2))
    end
    g.setColor(0.86,0.82,0.96,1)
    g.rectangle('fill',0,0,160,21);g.rectangle('fill',0,118,160,26)
    g.setColor(1,1,1,1)
    Font.draw(lines[self.phase],math.max(0,80-Font.width(lines[self.phase])/2),8)
    Font.draw(tr('A: CONTINUE','A: WEITER'),32,126)
    g.pop()
  end
  game.stack:push(scene);return true
end
return A
