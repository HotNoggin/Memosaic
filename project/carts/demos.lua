local demos = {}


demos["hello_world.memo"] =
[[
--!:name
--Hello World!

function boot()
    clrs()
    print("Hello World!")
end

function tick()
    -- Draw a random tile at a random position with random colors
    tile(
        rnd(0, 15), rnd(0, 15), -- Random position
        char(rnd(0x00, 0xff)),   -- Random char
        rnd(0, 15), rnd(0, 15)) -- Random colors
end

--!:font
--007e464a52627e007733770077577500005e42425e505000004c42424c5050000044424448504800005850585e585c0000003c3c3c3c0000003c765e5e763c001c1c7f7d7f1c1c001c147f7f7f1c1c001c1c7f5f7f1c1c001c1c7f7f7f141c003e7f6b776b7f3e003e7f636b637f3e001c147f5d7f141c00007e3e1e3e766200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005e5e000000000e0e000e0e0000247e7e247e7e2400005c5cd6d6747400006676381c6e660000347e4a763048000000000e0e00000000003c7e420000000000427e3c00000000041c0e1c0400000018187e7e181800000040606000000000181818181818000000006060000000006070381c0e0600003c7e524a7e3c000040447e7e404000006476725a5e4c00002466424a7e3400001e1e10107e7e00002e6e4a4a7a3200003c7e4a4a7a3000000606727a0e060000347e4a4a7e3400000c5e52527e3c000000006c6c0000000000406c6c0000000000183c664200000024242424242400000042663c180000000406525a1e0c00007c82baaab23c00007c7e0a0a7e7c00007e7e4a4a7e3400003c7e4242662400007e7e42427e3c00007e7e4a4a424200007e7e0a0a020200003c7e424a7a3800007e7e08087e7e000042427e7e42420000307040427e3e00007e7e181c766200007e7e40406060007e7e060c067e7e00007e7e0c187e7e00003c7e42427e3c00007e7e12121e0c00003c7e4262febc00007e7e0a0a7e7400002c4e5a5a7234000002027e7e020200003e7e40407e3e00001e3e70603e1e003e7e6030607e3e0000767e08087e760000060e7c780e0600004262725a4e460000007e7e4242000000060e1c38706000000042427e7e000000080c06060c080000404040404040000000060e0c00000000387c44443c7c00007f7f44447c380000387c44446c280000387c44447f7f0000387c54545c180000087e7f090b02000098bca4a4fcf800007f7f04047c78000044447d7d404000008080fdfd000000007f7f081c7662000040417f7f404000787c0c180c7c7800007c7c08047c780000387c44447c380000fcfc48447c380000387c4448fcfc80007c7c08041c180000585c545474300000043e7e44440000003c7c40407c7c00001c3c70603c1c003c7c6030607c3c00006c7c10107c6c00009cbca0a0fcfc00006474745c5c4c000000087e764200000000007e7e000000000042767e0800000010081818100800007e5a66665a7e00
]]


demos["new_cart.memo"] =
[[
--!:name
--New cart

--!:font
--007e464a52627e007733770077577500005e42425e505000004c42424c5050000044424448504800005850585e585c0000003c3c3c3c0000003c765e5e763c001c147f7f7f1c1c001c1c7f7f7f141c001c1c7f7d7f1c1c001c1c7f5f7f1c1c003e7f6b776b7f3e003e7f636b637f3e001c147f5d7f141c00007e3e1e3e766200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005e5e000000000e0e000e0e0000247e7e247e7e2400005c5cd6d6747400006676381c6e660000347e4a763048000000000e0e00000000003c7e420000000000427e3c00000000041c0e1c0400000018187e7e181800000040606000000000181818181818000000006060000000006070381c0e0600003c7e524a7e3c000040447e7e404000006476725a5e4c00002466424a7e3400001e1e10107e7e00002e6e4a4a7a3200003c7e4a4a7a3000000606727a0e060000347e4a4a7e3400000c5e52527e3c000000006c6c0000000000406c6c0000000000183c664200000024242424242400000042663c180000000406525a1e0c00007c82baaab23c00007c7e0a0a7e7c00007e7e4a4a7e3400003c7e4242662400007e7e42427e3c00007e7e4a4a424200007e7e0a0a020200003c7e424a7a3800007e7e08087e7e000042427e7e42420000307040427e3e00007e7e181c766200007e7e40406060007e7e060c067e7e00007e7e0c187e7e00003c7e42427e3c00007e7e12121e0c00003c7e4262febc00007e7e0a0a7e7400002c4e5a5a7234000002027e7e020200003e7e40407e3e00001e3e70603e1e003e7e6030607e3e0000767e08087e760000060e7c780e0600004262725a4e460000007e7e4242000000060e1c38706000000042427e7e000000080c06060c080000404040404040000000060e0c00000000387c44443c7c00007f7f44447c380000387c44446c280000387c44447f7f0000387c54545c180000087e7f090b02000098bca4a4fcf800007f7f04047c78000044447d7d404000008080fdfd000000007f7f081c7662000040417f7f404000787c0c180c7c7800007c7c08047c780000387c44447c380000fcfc48447c380000387c4448fcfc80007c7c08041c180000585c545474300000043e7e44440000003c7c40407c7c00001c3c70603c1c003c7c6030607c3c00006c7c10107c6c00009cbca0a0fcfc00006474745c5c4c000000087e764200000000007e7e000000000042767e0800000010081818100800007e5a66665a7e00
]]


demos["splash.memo"] =
[[
--!:name
--Splash

frame = 0

function boot()
    clrs()
    fframe = 0
    bframe = 0
    text = "  \1 MEMOSAIC \1  " -- Must be 16+ chars
end

function tick()
    clrs()
    fframe = (fframe + 1)
    bframe = (bframe + 1)

    fcolor = flr((fframe / 16) % 16)
    bcolor = flr(((bframe / 16) + 10) % 16)
    if fcolor > 15 then return end

    for x = 0, 15 do
        for y = 0, 15 do
            if y >= frame then
                tile(x, y, text:sub(x + 1, x + 1), fcolor, bcolor)
            end
        end
    end
end

--!:font
--007e464a52627e007733770077577500005e42425e505000004c42424c5050000044424448504800005850585e585c0000003c3c3c3c0000003c765e5e763c001c1c7f7d7f1c1c001c147f7f7f1c1c001c1c7f5f7f1c1c001c1c7f7f7f141c003e7f6b776b7f3e003e7f636b637f3e001c147f5d7f141c00007e3e1e3e766200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005e5e000000000e0e000e0e0000247e7e247e7e2400005c5cd6d6747400006676381c6e660000347e4a763048000000000e0e00000000003c7e420000000000427e3c00000000041c0e1c0400000018187e7e181800000040606000000000181818181818000000006060000000006070381c0e0600003c7e524a7e3c000040447e7e404000006476725a5e4c00002466424a7e3400001e1e10107e7e00002e6e4a4a7a3200003c7e4a4a7a3000000606727a0e060000347e4a4a7e3400000c5e52527e3c000000006c6c0000000000406c6c0000000000183c664200000024242424242400000042663c180000000406525a1e0c00007c82baaab23c00007c7e0a0a7e7c00007e7e4a4a7e3400003c7e4242662400007e7e42427e3c00007e7e4a4a424200007e7e0a0a020200003c7e424a7a3800007e7e08087e7e000042427e7e42420000307040427e3e00007e7e181c766200007e7e40406060007e7e060c067e7e00007e7e0c187e7e00003c7e42427e3c00007e7e12121e0c00003c7e4262febc00007e7e0a0a7e7400002c4e5a5a7234000002027e7e020200003e7e40407e3e00001e3e70603e1e003e7e6030607e3e0000767e08087e760000060e7c780e0600004262725a4e460000007e7e4242000000060e1c38706000000042427e7e000000080c06060c080000404040404040000000060e0c00000000387c44443c7c00007f7f44447c380000387c44446c280000387c44447f7f0000387c54545c180000087e7f090b02000098bca4a4fcf800007f7f04047c78000044447d7d404000008080fdfd000000007f7f081c7662000040417f7f404000787c0c180c7c7800007c7c08047c780000387c44447c380000fcfc48447c380000387c4448fcfc80007c7c08041c180000585c545474300000043e7e44440000003c7c40407c7c00001c3c70603c1c003c7c6030607c3c00006c7c10107c6c00009cbca0a0fcfc00006474745c5c4c000000087e764200000000007e7e000000000042767e0800000010081818100800007e5a66665a7e00
]]


demos["snek.lua"] = [[
--!:name
--snek

LEFT=1
RIGHT=2
UP=3
DOWN=4
DIRS={
	{x=-1,y= 0},
	{x= 1,y= 0},
	{x= 0,y=-1},
	{x= 0,y= 1},
}

BLEFT=0
BRIGHT=1
BUP=2
BDOWN=3

t=0
body={}
apples={}
dir=UP

function v2(x,y)
	return {
		x=x,
		y=y,
	}
end

function
v2cpy(v)
	return {
		x=v.x,
		y=v.y,
	}
end

function
v2add(a,b)
	return {
		x=a.x+b.x,
		y=a.y+b.y,
	}
end

function
rndpos()
	return v2(
		rnd(16)-1,
		rnd(16)-1
	)
end

function
onbody(pos)
	for i,v
	in pairs(body)
	do
		if v.x==pos.x
		and v.y==pos.y
		then
			return true
		end
	end

	return false
end

function
onbodyexhead(
pos)
	for i=1,#body-1
	do
		local v
			=body[i]

		if v.x==pos.x
		and v.y==pos.y
		then
			return true
		end
	end

	return false
end

function
onapple(pos)
	for i,v in
	pairs(apples)
	do
		if v.x==pos.x
		and v.y==pos.y
		then
			return true
		end
	end

	return false
end

function
rndapple()
	local pos
		=rndpos()

	while
	onbody(pos)
	or onapple(pos)
	do
		pos=rndpos()
	end

	return pos
end

function
around(pos)
	local v
		=v2cpy(pos)

	if v.x<0
	then
		v.x=15
	end
	if v.x>=16
	then
		v.x=0
	end
	if v.y<0
	then
		v.y=15
	end
	if v.y>=16
	then
		v.y=0
	end

	return v
end

function
ate(head)
	local h=head

	for i,v in
	pairs(apples)
	do
		if h.x==v.x
		and h.y==v.y
		then
			return i
		end
	end

	return 0
end

function reset()
	local
		start=rndpos()

	t=0
	body={
		v2cpy(start),
		v2cpy(start),
		v2cpy(start),
		v2cpy(start),
	}
	dir=rnd(4)
	apples={

		--the number
		--of
		--`rndapple()`
		--is the
		--number
		--of apples
		--in the game

		rndapple(),
		rndapple(),
	}
end

function
updatedir()
	if btn(BUP)
	then
		if dir~=DOWN
		then
			dir=UP
		end

	elseif
	btn(BDOWN)
	then
		if dir~=UP
		then
			dir=DOWN
		end

	elseif
	btn(BLEFT)
	then
		if dir~=RIGHT
		then
			dir=LEFT
		end
	
	elseif
	btn(BRIGHT)
	then
		if dir~=LEFT
		then
			dir=RIGHT
		end
	end
end

function
updatebody()
	local pos
		=body[#body]
	local nxpos
		=v2add(
			pos,
			DIRS[dir]
		)
	
	nxpos
		=around(nxpos)
	
	insert(
		body,
		nxpos
	)

	rmv(body,1)
end

function
drawbody()
	for i,v
	in pairs(body)
	do
		tile(
			v.x,
			v.y,
			16+1,
			13,
			8
		)
	end
end

function
drawapples()
	for i,v in
	pairs(apples)
	do
		tile(
			v.x,
			v.y,
			16+2,
			7,
			13
		)
	end
end

function boot()
	reset()
end

function tick()
	t=t+1
	
	updatedir()

	if t%6 == 0
	then
		updatebody()

		local head
			=body[#body]
		local i
			=ate(head)

		if i~=0 then
			rmv(apples,i)
			insert(
				apples,
				rndapple()
			)
			insert(
				body,
				1,
				v2cpy(
					body[1]
				)
			)
		end

		if
		onbodyexhead(
			head
		)
		then
			reset()
		end

		clrs(16,0,0)
		drawapples()
		drawbody()
	end
end

--!:font
--007E464A52627E007733770077577500005E42425E505000004C42424C5050000044424448504800005850585E585C0000003C3C3C3C0000003C765E5E763C001C147F7F7F1C1C001C1C7F7F7F141C001C1C7F7D7F1C1C001C1C7F5F7F1C1C003E7F6B776B7F3E003E7F636B637F3E001C147F5D7F141C00007E3E1E3E7662000000000000000000007E424242427E000018244242241800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005E5E000000000E0E000E0E0000247E7E247E7E2400005C5CD6D6747400006676381C6E660000347E4A763048000000000E0E00000000003C7E420000000000427E3C00000000041C0E1C0400000018187E7E181800000040606000000000181818181818000000006060000000006070381C0E0600003C7E524A7E3C000040447E7E404000006476725A5E4C00002466424A7E3400001E1E10107E7E00002E6E4A4A7A3200003C7E4A4A7A3000000606727A0E060000347E4A4A7E3400000C5E52527E3C000000006C6C0000000000406C6C0000000000183C664200000024242424242400000042663C180000000406525A1E0C00007C82BAAAB23C00007C7E0A0A7E7C00007E7E4A4A7E3400003C7E4242662400007E7E42427E3C00007E7E4A4A424200007E7E0A0A020200003C7E424A7A3800007E7E08087E7E000042427E7E42420000307040427E3E00007E7E181C766200007E7E40406060007E7E060C067E7E00007E7E0C187E7E00003C7E42427E3C00007E7E12121E0C00003C7E4262FEBC00007E7E0A0A7E7400002C4E5A5A7234000002027E7E020200003E7E40407E3E00001E3E70603E1E003E7E6030607E3E0000767E08087E760000060E7C780E0600004262725A4E460000007E7E4242000000060E1C38706000000042427E7E000000080C06060C080000404040404040000000060E0C00000000387C44443C7C00007F7F44447C380000387C44446C280000387C44447F7F0000387C54545C180000087E7F090B02000098BCA4A4FCF800007F7F04047C78000044447D7D404000008080FDFD000000007F7F081C7662000040417F7F404000787C0C180C7C7800007C7C08047C780000387C44447C380000FCFC48447C380000387C4448FCFC80007C7C08041C180000585C545474300000043E7E44440000003C7C40407C7C00001C3C70603C1C003C7C6030607C3C00006C7C10107C6C00009CBCA0A0FCFC00006474745C5C4C000000087E764200000000007E7E000000000042767E0800000010081818100800007E5A66665A7E00

]]


-- Export the demos
return demos