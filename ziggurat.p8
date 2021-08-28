pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--main


function _init()
	draw=strategicv_draw
	update=strategicv_update
	
	make_camera()
	make_cursor()
	init_map()
end

function _draw()
	draw()
	menu_draw()
end

function _update()
	update()
end

function make_camera()
end

function make_cursor()

end


-->8
--map

-- tiles
sand=4
river=42
fldpln=22

trrn_var={}

-- directions
-- w=1,sw=2,s=3,se=4,e=5
-- ne=6,n=7,nw=8
dirx={-1,-1,0,1,1,1,0,-1}
diry={ 0, 1,1,1,0,1,1, 1}

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
-->8
--strategic view

food_icon=28
pop_icon=38
idle_icon=39

function strategicv_update()
	move_cursor()
	handle_minimap()
	handle_select()
end

function strategicv_draw()
	cls()
	draw_map()
	draw_bldgs()
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
	
end

function handle_select() 
	if (btnp(5)) then
		local bldg = bldg_at_crsr()
		if (bldg != nil) then
			toggle_worked(bldg)
			return
		end
	
		show_menu({ 
			{
				text="build farm", 
				cb=build_farm
			},
			{
				text="build house",
				cb=build_house
			},
			{
				text="build wall",
				cb=build_wall 
			},
			{
				text="end turn",
				cb=end_turn
			}
		})
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

function draw_resource_bar()
	palt(0,false)
	rectfill(0,118,127,127,0)
	spr(pop_icon,1,119)
	print(total_pop(),11,121,7)
	spr(idle_icon,24,119)
	print(player.pop,34,121,7)
	spr(food_icon,43,119)
	print(get_food_per_turn(),53,121,7)
	local food_diff = get_food_diff()
	local c
	if (food_diff < 0) then
		c = 8
	else
		c = 11
	end
	print("("..food_diff..")",60,121,c)
	pal()
end
-->8
-- minimap view
minimap_color = {
	[river]=12,
	[sand]=15,
	[fldpln]=3
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

cmra={x=10,y=10}

crsr={x=8,y=8,sprite=1}

spear=7

tile_bldgs={
	[fldpln]={"farm"}
	[sand]={"house", "wall"}
}

bldg_cnfg={
	house={
		worked=6,
		unworked=36,
		takes_pop=false
	},
	farm={
		worked=23,
		unworked=35,
		takes_pop=true
	},
	wall={
		worked=9,
		unworked=9,
		takes_pop=false
	}
}

player={
	pop=1,
	food=0,
	bldgs={}
}

function add_unit_at_crsr(unit)
	local x = crsr.x + cmra.x
	local y = crsr.y + cmra.y
	add(player.bldgs,{
		x=x,
		y=y,
		typ=unit,
		worked=false
	})
end

function build_wall()
	add_unit_at_crsr("wall")
end

function build_farm()
	add_unit_at_crsr("farm")
end

function build_house()
	add_unit_at_crsr("house")
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
	return n+player.pop
end

function get_food_per_turn()
	return number_of_bldg("farm", true) * 2
end

function get_food_diff()
	return get_food_per_turn() - total_pop()
end

function end_turn()
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
		if (i == 0) break
		if (b.typ == "house") then
			b.worked = true
			i-=1
		end
	end
end

function toggle_worked(bldg)
	if (not bldg_config[bldg.typ].takes_pop) then
		return
	end
	if (not bldg.worked) then
		if (player.pop > 0) then
			bldg.worked=true
			player.pop-=1
		end
	else
		bldg.worked=false
		player.pop+=1
	end
end

function tile_at_crsr()
	local x=crsr.x + cmra.x
	local y=crsr.y + cmra.
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
	end
	if (btnp(2)) then
		selected_idx = max(
			selected_idx - 1,
			1
		)
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
0000000074444447f24fffffffffffffffffffff1c1c1c1cfffffffffff11f1fff4994ff49ff49fffffff49ff94fffff00000000000000000000000000000000
00000000470000742f944ffffff9ffffffffffffc1c1c1c1fff111ffff1881a1ff2992ff99999999ffff49999994ffff00000000000000000000000000000000
0070070040000004ffffffffff279fffffffffff1c1c1c1cf114441fff149191ff9999ff99449944fff4994444994fff00000000000000000000000000000000
0007700040000004ffff44ffff2779ffffffffffc1c1c1c11244491ff1111141ff4994ff24492449ff499949949994ff09000000000000000000000000000000
0007700040000004ff24f94ff2ff94ffffffffff1c1c1c1c1222991f12889141ff4994ff49244924ff499424424994ff09900000000000000000000000000000
0070070040000004fffffffff2ff994fffffffffc1c1c1c11212991f12889141ff2992ff24492449ff299449944992ff90900090000000000000000000000000
0000000047000074f29fff242ffff9f4fff99fff1c1c1c1c1212919991491121ff9999ff49244924ff999924429999ff99000990000000000000000000000000
00000000744444472ffff2f9ffffffffffffffffc1c1c1c19191199f99111919ff4994ffffffffffff4994ffff4994ff09040900000000000000000000000000
0000000000000000f4411ffff4411ffffffffffffffffffffffffffffffff1ffff49994ff49994ff1c1c1c1ccccc1ccc00040400000000000000000000000000
00000000000000004f1661ff4f1aa1ffff1111ffff1111ff93bb93bffff11911ff444999999444ffc1c1c1c1cc11c1cc04044404000000000000000000000000
0000000000000000f166651ff1aaa91ff124991ff124991ff99ff99f93319991ff292444444292ff1c1c1c1ccccccccc04449444000000000000000000000000
0000000000000000165776611a977aa1f121291ff121291f93b93bfff9914241ff444449944444ffc1c1c1c1cccccc1c04949494000000000000000000000000
0000000000000000165576611a997aa11221249112212491f933bfff933b111fff292924429292ff1c1c1c1ccccc11c104449444000000000000000000000000
0000000000000000f165561ff1a99a1f12711241127112419399f9bff999fffffff4444994444fffc1c1c1c1cc11cccc04944494000000000000000000000000
0000000000000000f4166144f41aa14419aa124115661241f93bbbff9333bbbffffff924429fffff1c1c1c1c11cc1ccc04994994000000000000000000000000
00000000000000004ff114f94ff114f9f111111ff111111f939999bff99999ffffffffffffffffffc1c1c1c1cccccccc04494944000000000000000000000000
000000000000000000000000fffff1ffffffffff0bb00a9a00024000000466660000400000000000cccc7ccc11111d1111111111000000000000000000000000
000000000000000000000000fff11611fff111ff00bba9a900244900004444600090009000000000cc12c6cc11d111d111111111000000000000000000000000
00000000000000000000000094416661f11ddd1f33ba9a9a00244400004446000099099000000000cccccccc111d111111111111000000000000000000000000
000000000000000000000000f991d5d115ddd61f0ba9a9a000224400004466660009090000000000cccccc7c1111111111111111000000000000000000000000
0000000000000000000000009444111f1555661f0b9a9ab000022000000440000990009900000000cccc12c61111111111111111000000000000000000000000
000000000000000000000000f999ffff1515661f0bb9abbb02444940066644400099099000000000cc27cccc11111d1111111111000000000000000000000000
0000000000000000000000009444449f15156199b3bbb30b2444449444644444040000040000000012cc6ccc1d1111d111111111000000000000000000000000
000000000000000000000000f99999ff9191199fbb00030024444494466644440044044000000000cccccccc11d1111111111111000000000000000000000000
__map__
040404042b2b0404040404040404040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
042c04042b2b0a090909090b040a090400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
042c040a0b2b0804040404080408040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
042b2b18192b0804042704080418090b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04042b2c042b0806060417080404040800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404042c062b080606042708040a091900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0404042b062b1809090909190408040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
040404042b2b2b2b2b2b2b2b0418090400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000b004703c470004703c470004703b470014703b470014703a470004703a470024703747004470304700b47026470124701e470184702047010470294700a4702d47004470314700047037470004703a470
