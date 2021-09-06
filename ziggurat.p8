pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--main
function _init()
	draw=strategicv_draw
	update=strategicv_update
	init_map()
end

function _draw()
	draw()
	menu_draw()
end

function _update()
	update()
end

-->8
--map

-- tiles
sand=4
river=42
fldpln=22
tin=18
copper=19

trrn_var={}

function gen_trrn_var()
	for x=1,map_size do
		for y=1,map_size do
			if (trrn_var[x] == nil) then
				trrn_var[x] = {}
			end
			trrn_var[x][y]=flr(rnd(10))
		end
	end
end

function generate_map()
	-- fill with blank tiles
	for x=1,map_size do
		for y=1,map_size do
		 if (map_tiles[x] == nil) then
				map_tiles[x] = {}
			end
		 map_tiles[x][y] = sand
		end
	end
	
	-- spawn rivers
	for i=1,flr(rnd(4))+2 do
		local river_x=flr(rnd(128))+1
		local river_y=1

		while (river_y <= 128) do
			map_tiles[river_x][river_y]=river
		
			spread_fldplns(river_x,river_y,2)
			
			-- no north dirs, flows
			-- south
			local rnd_dir=flr(rnd(5))+1
			river_x+=dirx[rnd_dir]
			river_y+=diry[rnd_dir]
			
			if (river_x < 1 or river_x > 127) then
				break
			end
		end
	end
	
	-- place ore
	for i=1,flr(rnd(80)+20) do
		local x = flr(rnd(128)+1)
		local y = flr(rnd(128)+1)
		local t
		if i % 2 == 0 then
			t = tin
		else 
			t = copper
		end
		
		map_tiles[x][y]=t
	end
end

function spread_fldplns(x,y,n)
	if (n==0) return
		
	for i=1,8 do
		fldpln_x=x+dirx[i]
		fldpln_y=y+diry[i]
		if (
			in_bounds(fldpln_x,fldpln_y)
			and map_tiles[fldpln_x][fldpln_y] != river
		) then
			map_tiles[fldpln_x][fldpln_y]=fldpln
			spread_fldplns(fldpln_x,fldpln_y,n-1)
		end
	end
end

function init_map()
	gen_trrn_var()
	generate_map()
end

function draw_map()
 for scrn_x=0,16 do
 	for scrn_y=0,16 do
 		x = scrn_x + cmra.x
 		y = scrn_y + cmra.y

 		map_tile = map_tiles[x][y]
 		var = trrn_var[x][y]
-- 		if (map_tile == sand) then
-- 			draw_sand(scrn_x*8,scrn_y*8,var)
-- 		else 
	 		spr(
	 			map_tile,
	 			(scrn_x)*8,
	 			(scrn_y)*8
	 		)
	 --	end
 	end
 end
end

function draw_sand(x,y,var)
 log("var: "..var)
	local shadow=var%6+1
	log("shadow: ",shadow)
	for i=1,7 do
		log("i: "..i)
		if i != shadow then
			pal(i,15)
		end
	end
	pal(shadow,9)
	spr(sand,x,y)
	pal()
end

function in_bounds(x,y)
	return x <= map_size
		and x > 0
		and y <= map_size
		and y > 0
end

-->8
--util

function log(txt)
	printh("debug: "..txt, "debug.txt")
end

function move_xy(_btn,x,y,mag)
	local xdir={-1,1,0,0}
	local ydir={0,0,-1,1}
	return x+xdir[_btn+1]*mag,y+ydir[_btn+1]*mag
end

-- directions
-- w=1,sw=2,s=3,se=4,e=5
-- ne=6,n=7,nw=8
w,sw,s,se,e,ne,n,nw=1,2,3,4,5,6,7,8
dirx={-1,-1,0,1,1,1,0,-1}
diry={ 0, 1,1,1,0,1,1, 1}

function get_dir(p, d)
	return { x=p+dirx[d], y=p+diry[d] }
end
-->8
--strategic view

food_icon=28
pop_icon=38
idle_icon=39
bricks_icon=41
copper_icon=55
tin_icon=54
bronze_icon=56

menu_lookup = { 
			farm={
				text="build farm (1)"
			},
			house={
				text="build house (1)"
			},
			wall={
				text="build wall (3)"
			},
			kiln={
				text="build kiln (2)"
			},
			copper_mine={
				text="build copper mine (2)"
			},
			tin_mine={
				text="build tin mine (2)"
			},
			smelter={
				text="build smelter (2)"
			},
			barracks={
				text="build barracks (2)"
			},
			admin={
				text="build admin (2)"
			},
			end_turn={
				text="end turn"
			}
}

function grid_to_screen(p)
	return {
		x=(p.x-cmra.x)*8,
		y=(p.y-cmra.y)*8
	} 
end

function strategicv_update()
	move_cursor()
	handle_minimap()
	handle_select()
end

function strategicv_draw()
	cls()
	draw_map()
	draw_bldgs()
	draw_armies()
	draw_borders()
	draw_cursor()
	draw_resource_bar()
end

function handle_minimap()
	if (btnp(4)) then
		update=minimapv_update
		draw=minimapv_draw
	end
end

function get_build_menu()
	local tile = tile_at_crsr()
	local bldgs = tile_bldgs[tile]
	local menu = {}
	for b in all(bldgs) do
		add(menu, menu_lookup[b])
	end
	add(menu, menu_lookup.end_turn)
	return menu
end

function handle_select() 
	if (btnp(5)) then
		local bldg = bldg_at_crsr()
		if (bldg != nil) then
			toggle_worked(bldg)
			return
		end
	
		show_menu(get_build_menu())
	end
end

function move_cursor()
	for i=0,3 do
		if (btnp(i)) then
			local cx,cy=move_xy(i,cmra.x,cmra.y,1)
			cmra.x=cx
			cmra.y=cy
			return
		end
	end
end

function draw_cursor()
	spr(crsr.sprite,crsr.x*8,crsr.y*8)
end

function draw_bldgs()
	for b in all(player.bldgs) do
	 map_x = b.x - cmra.x
	 map_y = b.y - cmra.y
	 if (map_x >= 0 
	     and map_x <= 15
	     and map_y >=0
	     and map_y <= 15) then
	  local sprite
	  if (b.worked) then
	  	sprite=bldg_cnfg[b.typ].worked
	  else
	  	sprite=bldg_cnfg[b.typ].unworked
	  end
			spr(sprite,map_x*8,map_y*8)
		end
	end
end

function draw_armies()
	for a in all(player.armies) do
		spr(
			army,
			(a.x-cmra.x)*8,
			(a.y-cmra.y)*8
		)
	end
end

function draw_resource_bar()
	palt(0,false)
	rectfill(0,0,8*3,8*9,0)
	rect(-1,-1,8*3,8*9,4)
	-- pop
	spr(pop_icon,0,0)
	print(total_pop(),10,2,7)
	-- idles
	spr(idle_icon,0,9*1)
	print(player.pop,10,2+9,7)
	-- food
	spr(food_icon,0,9*2)
	print(get_food_per_turn(),10,2+9*2,7)
	local food_diff = get_food_diff()
	local c
	if (food_diff < 0) then
		c = 8
	else
		c = 11
	end
	print("("..food_diff..")",0,2+9*3,c)
	-- bricks
	spr(bricks_icon,0,9*4)
	print(player.bricks,10,2+9*4,7)
	--tin
	spr(tin_icon,0,9*5)
	print(player.tin,10,2+9*5,7)
	-- copper
	spr(copper_icon,0,9*6)
	print(player.copper,10,2+9*6,7)
	-- bronze
	spr(bronze_icon,0,9*7)
	print(player.bronze,10,2+9*7,7)
	pal()
end

function draw_borders()
	local r = admin_radius
	local admins = all_bldgs("admin")
	for a in all(admins) do
		log(a.x.." "..a.y)
		local s_p = grid_to_screen(a)
		circ(s_p.x+4, s_p.y+4,r*8,8)
		-- bresenham's algo
		-- start at top
		local circle_point = { x=a.x, y=a.y-admin_radius }
		local f_m = 5/4 - r
		while (circle_point.x-a.x < circle_point.y-a.y) do
			local cp_scrn=grid_to_screen(circle_point)
			circ(cp_scren.x+4,cp_scrn.y+4,4,9)
		end
	end
end
-->8
-- minimap view
minimap_color = {
	[river]=12,
	[sand]=15,
	[fldpln]=3,
	[copper]=10,
	[tin]=6
}

function minimapv_update()
	handle_close_minimap()
	handle_move_camera()
end

function minimapv_draw()
	cls()
	draw_minimap()
end

function handle_close_minimap()
	if (btnp(4)) then
		draw=strategicv_draw
		update=strategicv_update
	end
end

function handle_move_camera()
	for i=0,3 do
		if (btnp(i)) then
			local x,y = move_xy(i,cmra.x,cmra.y,5)
			cmra.x=x
			cmra.y=y
			return
		end
	end
end

function draw_minimap()
	for x=0,127 do
		for y=0,127 do
			local tile = map_tiles[x+1][y+1]
			pset(x,y,minimap_color[tile])
		end
	end
	for u in all(player.bldgs) do
		pset(u.x,u.y,8)
	end
	rect(
		cmra.x,
		cmra.y,
		cmra.x+16,
		cmra.y+16,
		7
	)
end
-->8
-- game model
map_tiles={}
map_size=128

admin_radius=4

cmra={x=10,y=10}

crsr={x=8,y=8,sprite=1}

army=7

end_turn_sfx=3
work_sfx=4
unwork_sfx=5

tile_bldgs={
	[fldpln]={"farm"},
	[sand]={
		"house", 
		"wall",
		"kiln",
		"smelter",
		"barracks",
		"admin"
	},
	[river]={},
	[copper]={"copper_mine"},
	[tin]={"tin_mine"}
}

bldg_cnfg={
	house={
		worked=6,
		unworked=36,
		takes_pop=false,
		cost=1
	},
	farm={
		worked=23,
		unworked=35,
		takes_pop=true,
		cost=1
	},
	wall={
		worked=9,
		unworked=9,
		takes_pop=false,
		cost=3
	},
	kiln={
		worked=34,
		unworked=33,
		takes_pop=true,
		cost=2
	},
	tin_mine={
		worked=21,
		unworked=30,
		takes_pop=true,
		cost=2
	},
	copper_mine={
		worked=20,
		unworked=29,
		takes_pop=true,
		cost=2
	},
	smelter={
		worked=50,
		unworked=51,
		takes_pop=true,
		cost=2
	},
	barracks={
		worked=52,
		unworked=53,
		takes_pop=true,
		cost=2
	},
	admin={
		worked=57,
		unworked=58,
		takes_pop=false,
		cost=2
	}
}

player={
	pop=1,
	food=0,
	bldgs={},
	bricks=10,
	copper=0,
	tin=0,
	bronze=10,
	armies={}
}

function add_unit_at_crsr(unit, worked)
	local x = crsr.x + cmra.x
	local y = crsr.y + cmra.y
	add(player.bldgs,{
		x=x,
		y=y,
		typ=unit,
		worked=worked
	})
end

function build_bldg(unit, worked)
	worked = worked or false
	local cost = bldg_cnfg[unit].cost
	if (player.bricks >= cost) then
		add_unit_at_crsr(unit, true)
		player.bricks-=cost
		sfx(2)
	end
end

function build_wall()
	build_bldg("wall")
end
menu_lookup.wall.cb=build_wall

function build_farm()
	build_bldg("farm")
end
menu_lookup.farm.cb=build_farm

function build_house()
	build_bldg("house")
end
menu_lookup.house.cb=build_house

function build_kiln()
	build_bldg("kiln")
end
menu_lookup.kiln.cb=build_kiln

function build_copper_mine()
	build_bldg("copper_mine")
end
menu_lookup.copper_mine.cb=build_copper_mine

function build_tin_mine()
	build_bldg("tin_mine")
end
menu_lookup.tin_mine.cb=build_tin_mine

function build_smelter()
	build_bldg("smelter")
end
menu_lookup.smelter.cb=build_smelter

function build_barracks()
	build_bldg("barracks")
end
menu_lookup.barracks.cb=build_barracks

function build_admin()
	build_bldg("admin", true)
end
menu_lookup.admin.cb=build_admin

function all_bldgs(typ)
	local bldgs = {}
	for b in all(player.bldgs) do
		if (b.typ == typ) then
			add(bldgs, b)
		end
	end
	return bldgs
end

function number_of_bldg(bldg,worked)
	local n=0
	for b in all(player.bldgs) do
		if (b.typ == bldg and b.worked == worked) then
			n+=1
		end
	end
	return n
end

function total_pop()
	local n=0
	for b in all(player.bldgs) do
		if (b.worked and bldg_cnfg[b.typ].takes_pop) then
			n+=1
		end
	end
	return n+player.pop+#player.armies
end

function get_food_per_turn()
	return number_of_bldg("farm", true) * 2
end

function get_food_diff()
	return get_food_per_turn() - total_pop()
end

function end_turn()
	sfx(end_turn_sfx)
	log("end turn:")
	-- calc food
	player.food = get_food_per_turn()
		
	log("total food: "..player.food)
	-- grow pop
	local empty_houses = 
		(number_of_bldg("house",true)
		+ number_of_bldg("house",false))
		- total_pop()
	log("empty houses: "..empty_houses)
	
	local excess_food = get_food_diff()
	log("excess_food: "..excess_food)
	
	log("pop: "..player.pop)
	player.pop+=min(empty_houses,excess_food)
	log("pop adjust: "..player.pop)
	
	player.food-=total_pop()
	log("food adjust: "..player.food)
	
	-- occupy houses
	i=total_pop()
	for b in all(player.bldgs) do
		if (b.typ == "house") then
			if (i > 0) then 
				b.worked = true
				i-=1
		 else
		 	b.worked = false
			end
		end
	end
	
	-- add bricks
	local bricks=number_of_bldg("kiln",true)
	player.bricks+=bricks
	
	-- add copper
	player.copper+=number_of_bldg("copper_mine",true)
	
	-- add tin
	player.tin+=number_of_bldg("tin_mine",true)
	
	-- smelt bronze
	local new_bronze = min(number_of_bldg("smelter",true),player.copper,player.tin)
	log("nb: "..new_bronze)
	
	player.bronze+=new_bronze
	player.tin-=new_bronze
	player.copper-=new_bronze
	
	-- train units
	for b in all(player.bldgs) do
		if (b.typ == "barracks" and player.bronze > 0 and b.worked) then
			b.worked=false
			player.bronze-=1
			spawn_army_near(b.x,b.y)
		end
	end
end
menu_lookup.end_turn.cb=end_turn

function spawn_army_near(x,y)
	add(player.armies,{x=x-1,y=y})
end

function toggle_worked(bldg)
	if (not bldg_cnfg[bldg.typ].takes_pop) then
		return
	end
	if (not bldg.worked) then
		if (player.pop > 0) then
			bldg.worked=true
			player.pop-=1
			sfx(work_sfx)
		end
	else
		bldg.worked=false
		player.pop+=1
		sfx(unwork_sfx)
	end
end

function tile_at_crsr()
	local x=crsr.x + cmra.x
	local y=crsr.y + cmra.y
	return map_tiles[x][y]
end

function bldg_at_crsr()
	local x=crsr.x + cmra.x
	local y=crsr.y + cmra.y
	for b in all(player.bldgs) do
		if (b.x == x and b.y == y) then
			return b
		end
	end
end
-->8
-- ui

-- constants
menu_height=100
menu_width=60

menu_move_sfx=0


-- state
selected_idx=1
menu_items={}
menu_shown=false
stored_update=nil

function show_menu(items)
	menu_items=items
	menu_shown=true
	stored_update=update
	update=menu_update
end

function hide_menu()
	menu_items={}
	menu_shown=false
	selected_idx=1
	update=stored_update
end

function menu_update()
	handle_menu_close()
 handle_menu_move()
	handle_menu_select()
end

function handle_menu_select()
	if (btnp(5)) then
		menu_items[selected_idx].cb()
		hide_menu()
	end
end

function handle_menu_move()
	if (btnp(3)) then
		selected_idx = min(
			selected_idx + 1,
			#menu_items
		)
		sfx(menu_move_sfx)
	end
	if (btnp(2)) then
		selected_idx = max(
			selected_idx - 1,
			1
		)
		sfx(menu_move_sfx)
	end
	
end

function menu_draw()
	if (menu_shown) then
		rectfill(
			16, 16, 
			16+menu_height, 
			16+menu_width, 
			4
		)
		for i=1,#menu_items do
			local y = 20 + (i-1)*8
			local s = menu_items[i].text

			if (i == selected_idx) then
				s = "◆ "..s
			end
			
			print(s,20,y,7)
		end
	end
end

function handle_menu_close()
	if (btnp(4)) then
		hide_menu()
	end
end


__gfx__
0000000074444447f24fffffffffffffffffffff1c1c1c1cfffffffffff11f1fff4994ff49ff49fffffff49ff94fffff00000000fff11f1f0000000000000000
00000000470000742f944ffffff9ffffffffffffc1c1c1c1fff111ffff1881a1ff2992ff99999999ffff49999994ffff00000000ff1cc1a10000000000000000
0070070040000004ffffffffff279fffffffffff1c1c1c1cf114441fff149191ff9999ff99449944fff4994444994fff00000000ff1491910000000000000000
0007700040000004ffff44ffff2779ffffffffffc1c1c1c11244491ff1111141ff4994ff24492449ff499949949994ff09000000f11111410000000000000000
0007700040000004ff24f94ff2ff94ffffffffff1c1c1c1c1222991f12889141ff4994ff49244924ff499424424994ff099000001dcc91410000000000000000
0070070040000004fffffffff2ff994fffffffffc1c1c1c11212991f12889141ff2992ff24492449ff299449944992ff909000901dcc91410000000000000000
0000000047000074f29fff242ffff9f4fff99fff1c1c1c1c1212919991491121ff9999ff49244924ff999924429999ff99000990914911210000000000000000
00000000744444472ffff2f9ffffffffffffffffc1c1c1c19191199f99111919ff4994ffffffffffff4994ffff4994ff09040900991119190000000000000000
0000000000000000f4411ffff4411ffffffffffffffffffffffffffffffff1ffff49994ff49994ff1c1c1c1ccccc1ccc00040400ffffffffffffffff00000000
00000000000000004f1661ff4f1aa1ffff1111ffff1111ff93bb93bffff11911ff444999999444ffc1c1c1c1cc11c1cc04044404ff1111ffff1111ff00000000
0000000000000000f166651ff1aaa91ff124991ff124991ff99ff99f93319991ff292444444292ff1c1c1c1ccccccccc04449444f15d661ff15d661f00000000
0000000000000000165776611a977aa1f121291ff121291f93b93bfff9914241ff444449944444ffc1c1c1c1cccccc1c04949494f151561ff151561f00000000
0000000000000000165576611a997aa11221249112212491f933bfff933b111fff292924429292ff1c1c1c1ccccc11c10444944415515d6115515d6100000000
0000000000000000f165561ff1a99a1f12711241127112419399f9bff999fffffff4444994444fffc1c1c1c1cc11cccc04944494157115d1157115d100000000
0000000000000000f4166144f41aa14419aa124115661241f93bbbff9333bbbffffff924429fffff1c1c1c1c11cc1ccc0499499419aa15d1156615d100000000
00000000000000004ff114f94ff114f9f111111ff111111f939999bff99999ffffffffffffffffffc1c1c1c1cccccccc04494944f111111ff111111f00000000
00000000ff111fffff1111fffffff1ffffffffff0bb00a9a00024000000266660000400000000000cccc7ccc11111d1111111111000000000000000000000000
00000000f15dd1fff16561fffff11611fff111ff00bba9a900244900002449600090009000000000cc12c6cc11d111d111111111000000000000000000000000
0000000015dd6d1f1256541f94416661f11ddd1f33ba9a9a00244400002446000099099000049900cccccccc111d111111111111000000000000000000000000
0000000015ddd6d112654941f991d5d115ddd61f0ba9a9a000224400002266660009090000044900cccccc7c1111111111111111000000000000000000000000
000000001555dd51125244219444111f1555661f0b9a9ab000022000000220000990009900000000cccc12c61111111111111111000000000000000000000000
000000001522555112892221f999ffff1515661f0bb9abbb02444940066644900099099004990499cc27cccc11111d1111111111000000000000000000000000
000000001522551f1288221f9444449f15156199b3bbb30b2444449424644444040000040449044912cc6ccc1d1111d111111111000000000000000000000000
000000009111119991111199f99999ff9191199fbb00030024444494266644440044044000000000cccccccc11d1111111111111000000000000000000000000
0000000000000000fff111fffff111fff4444ffff5555fff000000000000000000000000ffffffffffffffff0000000000000000000000000000000000000000
0000000000000000ff12291fff15561ff4fff4fff5fff5ff00066000000aa00000099000f444444ff555555f0000000000000000000000000000000000000000
0000000000000000f1122941f11556d1f4fff4fff5fff5ff0066650000aaa90000999400f4ffff4ff5ffff5f0000000000000000000000000000000000000000
00000000000000001244449115dddd61f4444ffff5555fff065776600a977aa009477990f4ffff4ff5ffff5f0000000000000000000000000000000000000000
00000000000000001222299115555661f4fff4fff5fff5ff065576600a997aa009447990f444444ff555555f0000000000000000000000000000000000000000
00000000000000001289299115895661f4fff4fff5fff5ff0065560000a99a0000944900f4ffff4ff5ffff5f0000000000000000000000000000000000000000
00000000000000001288291f1588561ff4444ffff5555fff00066000000aa00000099000f4ffff4ff5ffff5f0000000000000000000000000000000000000000
00000000000000009111119991111199ffffffffffffffff000000000000000000000000ffffffffffffffff0000000000000000000000000000000000000000
__map__
0d0d0d0d0d040404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0d0d0d07070704040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0d0d0d07070707040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0d0d0707070704040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d0d07070707040a090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d07070707070408060606060422220400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d07070707040408060606060422220400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404070704040408040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0002000000400197201e7301e720197203b400014003b400014003a400004003a400024003740004400304000b40026400124001e400184002040010400294000a4002d40004400314000040037400004003a400
0001000000000297502975027750217502f7003470011750107500f7500e7500d75000000000000000000000293002a3002a30000000000000000000000000000000000000000000000000000000000000000000
000200000000006730077300563000000000000000012710147200f62000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000000001105000000000001c05000000130501305000000080001d000140001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000b7500e7501175015750197501d7502075023750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000207501e7501c7501a75017750147501375012750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
