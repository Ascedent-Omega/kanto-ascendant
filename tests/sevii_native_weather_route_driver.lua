return function(game)
 local root=assert(os.getenv('SEVII_KASC_ROOT'));local out=assert(os.getenv('SEVII_QA_OUTPUT'));local U=require('tests.drivers.util');local Q=dofile(root..'/tests/habitat_playthrough/drivers/common.lua')(game);Q.setup()
 local S=Q.K.seviiExpedition;local fixed=os.getenv('SEVII_EXPECT_FIXED')=='1';local camera=tonumber(os.getenv('SEVII_COMPONENT_CAMERA')or'0');local rows={}
 for _,character in ipairs{'RED','BLUE','GREEN'}do
  local site=S.weatherTrio.sites[character];local map=S.maps[site.map];local entry
  for _,delta in ipairs{{0,-1,'down'},{0,1,'up'},{-1,0,'right'},{1,0,'left'}}do
   if S.walkable(site.map,site.x+delta[1],site.y+delta[2])then entry=delta;break end
  end
  assert(entry);U.teleport(game,site.map,site.x+entry[1],site.y+entry[2],entry[3]);Q.settle();local pipes=require('src.render.Pipelines');pipes.setLevel('voxel',camera);pipes.syncOptions(game.save.options);Q.settle()
  assert(U.still(game,out..'/'..character..'-approach.png'));U.hold(game,entry[3],2);U.wait(60);Q.settle()
  local p=game.overworld.player;local crossed=p.cellX==site.x and p.cellY==site.y
  rows[#rows+1]={character=character,map=site.map,x=site.x,y=site.y,crossed=crossed,fromX=site.x+entry[1],fromY=site.y+entry[2]}
  if character=='RED'then assert(crossed==fixed,'Groudon sole corridor must agree with expected version')end
  if fixed then assert(crossed,'all optional weather sites remain traversable '..character)end
  assert(U.still(game,out..'/'..character..'-movement.png'))
 end
 local f=assert(io.open(out..'/weather-route.json','w'));f:write(require('src.link.Json').encode({camera=camera,fixed=fixed,rows=rows,scope='Actual native movement onto authored seal coordinates with gates unmet. Initial champion/team/adjacent position are isolated QA fixtures.'}));f:close();print('SEVII_WEATHER_ROUTE_REPRO_PASS',tostring(fixed));love.event.quit()
end
