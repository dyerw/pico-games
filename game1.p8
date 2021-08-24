pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
rifle=5

units={{x=0,y=0,sprite=rifle}}

function _init()
 make_camera()
	make_cursor()
	make_map()
end

function _update()
	move_cursor()
	move_camera()
end

function _draw()
	cls()
	draw_map()
	draw_units()
	draw_cursor()
end

function make_camera()
	cmra={}
	cmra.x=0
	cmra.y=0
end

function make_cursor()
	crsr={}
	crsr.x=8
	crsr.y=8
	crsr.sprite=1
end

function make_map()
	for x=0,100 do
		for y=0,100 do
			mset(x,y,flr(rnd(3))+2)
		end
	end
end

function move_cursor()
 new_x = crsr.x
 new_y = crsr.y
	if (btn(0)) new_x-=1
	if (btn(1)) new_x+=1
	if (btn(2)) new_y-=1
	if (btn(3)) new_y+=1
	
	if (new_x < cmra.x) then
		cmra.x-=1
	end
	
	crsr.x = new_x
	crsr.y = new_y
end

function move_camera()
	camera(cmra.x*8, cmra.y*8)
end

function draw_cursor()
	spr(crsr.sprite,crsr.x*8,crsr.y*8)
end

function draw_map()
	map(16,16,0,0,16,16)
end

function draw_units()
	for u in all(units) do
		spr(u.sprite,u.x,u.y)
	end
end
__gfx__
0000000074444447f44fffffffffffffffffffffffff994f00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000470000744f944ffffff4fffffffffffffff33b4f00000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070040000004ffffffffff474fffffffffffffff994f00000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700040000004ffff44ffff4774ffffffffff5466644400000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700040000004ff44f94ff4ff94ffffffffffff44994400000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070040000004fffffffff4ff994fffffffffffff994f00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000047000074f49fff444ffff9f4fffffffffff9994f00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000744444474ffff4f9fffffffffffffffffff9ff4400000000000000000000000000000000000000000000000000000000000000000000000000000000
