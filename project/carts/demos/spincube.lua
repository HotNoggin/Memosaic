return

[[
--!:lua
--!:name
--spincube
--!:author
--TripleCubes

function
v3(x,y,z)
	return {
		x=x,
		y=y,
		z=z,
	}
end

t=0
verts={
	v3(-1, 1,-1),
	v3( 1, 1, 1),
	v3(-1, 1, 1),

	v3(-1, 1,-1),
	v3( 1, 1,-1),
	v3( 1, 1, 1),

	v3(-1,-1,-1),
	v3(-1,-1, 1),
	v3( 1,-1, 1),

	v3(-1,-1,-1),
	v3( 1,-1, 1),
	v3( 1,-1,-1),

	v3(-1, 1,-1),
	v3(-1, 1, 1),
	v3(-1,-1, 1),

	v3(-1, 1,-1),
	v3(-1,-1, 1),
	v3(-1,-1,-1),

	v3( 1, 1,-1),
	v3( 1,-1, 1),
	v3( 1, 1, 1),

	v3( 1, 1,-1),
	v3( 1,-1,-1),
	v3( 1,-1, 1),

	v3(-1, 1, 1),
	v3( 1, 1, 1),
	v3(-1,-1, 1),

	v3( 1, 1, 1),
	v3( 1,-1, 1),
	v3(-1,-1, 1),

	v3(-1, 1,-1),
	v3(-1,-1,-1),
	v3( 1, 1,-1),

	v3( 1, 1,-1),
	v3(-1,-1,-1),
	v3( 1,-1,-1),
}
depthbuf={}
chars={
	16+1,
	16+2,
	16+3,
	16+4,
	16+5,
	16+6,
	16+7,
	16+8,
	16+9,
	16+10,
}
local colors={
	3,4,5,6,7,8,
	10,11,12,13,
	14,15,
}

function
vrotx(v,r)
	return v3(
		v.x,

		v.y*cos(r)
		-v.z*sin(r),

		v.y*sin(r)
		+v.z*cos(r)
	)
end

function
vroty(v,r)
	return v3(
		v.x*cos(r)
		-v.z*sin(r),

		v.y,

		v.x*sin(r)
		+v.z*cos(r)
	)
end

function
vrotz(v,r)
	return v3(
		v.x*cos(r)
		-v.y*sin(r),

		v.x*sin(r)
		+v.y*cos(r),

		v.z
	)
end

function
vrot(v,x,y,z)
	local vx
		=vrotx(v,x)
	local vy
		=vroty(vx,y)
	local vz
		=vrotz(vy,z)
	return vz
end

function
vmap(v)
	return v3(
		v.x*8+8,
		v.y*8+8,
		v.z
	)
end

function
vmul(v,n)
	return v3(
		v.x*n,
		v.y*n,
		v.z*n
	)
end

function
vdiv(v,n)
	return v3(
		v.x/n,
		v.y/n,
		v.z/n
	)
end

function
vadd(a,b)
	return v3(
		a.x+b.x,
		a.y+b.y,
		a.z+b.z
	)
end

function
vsub(a,b)
	return v3(
		a.x-b.x,
		a.y-b.y,
		a.z-b.z
	)
end

function
vlen(v)
	return
		sqrt(v.x*v.x
			+v.y*v.y
			+v.z*v.z)
end

function
vnorm(v)
	return vdiv(
		v, vlen(v)
	)
end

function
vcross(a,b)
	return v3(
		a.y*b.z
		-a.z*b.y,

		a.z*b.x
		-a.x*b.z,

		a.x*b.y
		-a.y*b.x
	)
end

function
vdot(a,b)
	return
	a.x*b.x
	+a.y*b.y
	+a.z*b.z
end

function
vproj(v)
	return v3(
		v.x/-v.z,
		v.y/-v.z,
		v.z
	)
end

function
clamp(v,min,max)
	if v<min then
		return min
	end
	if v>max then
		return max
	end
	return v
end

function
ratio(
	x,
	x0,x1,
	y0,y1)
	local dx1
		=abs(x1-x0)
	local dx
		=abs(x-x0)
	local r=dx/dx1

	local dy1
		=y1-y0
	return
		dy1*r+y0
end

function
max3(a,b,c)
	if a>=b
	and a>=c then
		return a
	
	elseif b>=a
	and b>=c then
		return b

	else
		return c
	end
end

function
min3(a,b,c)
	if a<=b
	and a<=c then
		return a
	
	elseif b<=a
	and b<=c then
		return b

	else
		return c
	end
end

function
lnintersect(
	y,v1,v2
)
	if v1.x==v2.x
	then
		return v1.x
	end
	if v1.y==v2.y
	then
		return v1.x
	end

	local g
		=(v2.y-v1.y)
		/(v2.x-v1.x)
	local i
		=v1.y-(g*v1.x)
		
	local x=(y-i)/g
	local z=ratio(
		x,v1.x,v2.x,
		v1.z,v2.z
	)
	return x,z
end

function
intersect(
	y,v1,v2,v3
)
	y=y+0.5
	if v1.y>=y
	and v2.y>=y
	and v3.y>=y
	then
		return
			v1.x,v1.x,
			v1.z,v1.z
	end
	if v1.y<=y
	and v2.y<=y
	and v3.y<=y
	then
		return
			v1.x,v1.x,
			v1.z,v1.z
	end

	local sides={
		{v1,v2},
		{v2,v3},
		{v3,v1},
	}

	for i,v in
	pairs(sides) do
		if v[1].y>=y
		and v[2].y>=y
		then
			rmv(sides,i)
			break
		end

		if v[1].y<=y
		and v[2].y<=y
		then
			rmv(sides,i)
			break
		end
	end

	local x0,z0
		=lnintersect(
			y,
			sides[1][1],
			sides[1][2]
		)
	local x1,z1
		=lnintersect(
			y,
			sides[2][1],
			sides[2][2]
		)
	
	if x0>x1 then
		local swap=x0
		x0=x1
		x1=swap

		swap=z0
		z0=z1
		z1=swap
	end
	return x0,x1,
		z0,z1
end

function
ln(x0,x1,y,
z0,z1,char)
	if x0==x1 then
		return
	end

	for x
	=(x0),
	ceil(x1) do
		if x<0
		or x>=16 then
			goto cont
		end

		local z=ratio(
			x,x0,x1,
			z0,z1
		)

		if
		depthbuf
		[flr(y+1)]
		[flr(x+1)]
		>z then
			goto cont
		end

		depthbuf
		[flr(y+1)]
		[flr(x+1)]
			=z
		tile(
			flr(x),
			flr(y),
			chars[char],
			colors[
				flr(t/10)
				%#colors+1
			],
			0
		)

		::cont::
	end
end

function
scanln(v1,v2,v3,
char)
	local topy
		=min3(
			v1.y,
			v2.y,
			v3.y
		)
	topy=clamp(
		topy,0,15
	)
	local boty
		=max3(
			v1.y,
			v2.y,
			v3.y
		)
	boty=clamp(
		boty,0,15
	)

	for y
	=topy,
	boty
	do
		local x0,x1,
		z0,z1
			=intersect(
				y,v1,v2,v3
			)

		ln(
			x0,
			x1,
			y,
			z0,
			z1,
			char
		)
	end
end

function
v3drot(v)
	v=vrot(
		v,
		t/30,
		t/50,
		t/40
	)
	return v
end

function
v3d2d(v)
	v=vadd(
		v,
		v3(0,0,-3)
	)
	v=vproj(v)
	v=vmul(v,1.2)
	v=vmap(v)
	return v
end

function
clrdepthbuf()
	for y=1,16 do
	for x=1,16 do
		depthbuf[y][x]
			=-100
	end
	end
end

function boot()
	for y=1,16 do
		insert(
			depthbuf,
			{}
		)
		for x=1,16 do
			insert(
				depthbuf[y],
				0
			)
		end
	end
end

function tick()
	t=t+1
	clrs(0,0,0)
	clrdepthbuf()

	for i
	=1,#verts,3
	do
		local _v1
			=verts[i]
		local _v2
		 =verts[i+1]
		local _v3
		 =verts[i+2]

		_v1
			=v3drot(_v1)
		_v2
			=v3drot(_v2)
		_v3
			=v3drot(_v3)

		local nor
			=vcross(
				vsub(
					_v2,
					_v1
				),
				vsub(
					_v3,
					_v2
				)
			)
		nor=vnorm(nor)

		if vdot(
			nor,
			v3(0,0,-1)
		)<0 then
			goto cont
		end

		local char
			=vdot(
				vnorm(v3(
					0.6,
					0.7,
					-1
				)),
				nor
			)
		char=clamp(
			char,0,1
		)
		char
			=char*9.9+1
		char
			=flr(char)

		_v1=v3d2d(_v1)
		_v2=v3d2d(_v2)
		_v3=v3d2d(_v3)

		scanln(
			_v1,
			_v2,
			_v3,
			char
		)

		::cont::
	end
end



--!:font
--007E464A52627E007733770077577500005E42425E505000004C42424C5050000044424448504800005850585E585C0000003C3C3C3C0000003C765E5E763C001C147F7F7F1C1C001C1C7F7F7F141C001C1C7F7D7F1C1C001C1C7F5F7F1C1C003E7F6B776B7F3E003E7F636B637F3E001C147F5D7F141C00007E3E1E3E766200000000000000000000000008000000000000001808000000000000181800000000000C1C1800000000001C1C1C00000000001C3C3C38000000003C3C3C3C0000001E3E3E3E3C0000003E3E3E3E3E0000003E7E7E7E7E7C000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005E5E000000000E0E000E0E0000247E7E247E7E2400005C5CD6D6747400006676381C6E660000347E4A763048000000000E0E00000000003C7E420000000000427E3C00000000041C0E1C0400000018187E7E181800000040606000000000181818181818000000006060000000006070381C0E0600003C7E524A7E3C000040447E7E404000006476725A5E4C00002466424A7E3400001E1E10107E7E00002E6E4A4A7A3200003C7E4A4A7A3000000606727A0E060000347E4A4A7E3400000C5E52527E3C000000006C6C0000000000406C6C0000000000183C664200000024242424242400000042663C180000000406525A1E0C00007C82BAAAB23C00007C7E0A0A7E7C00007E7E4A4A7E3400003C7E4242662400007E7E42427E3C00007E7E4A4A424200007E7E0A0A020200003C7E424A7A3800007E7E08087E7E000042427E7E42420000307040427E3E00007E7E181C766200007E7E40406060007E7E060C067E7E00007E7E0C187E7E00003C7E42427E3C00007E7E12121E0C00003C7E4262FEBC00007E7E0A0A7E7400002C4E5A5A7234000002027E7E020200003E7E40407E3E00001E3E70603E1E003E7E6030607E3E0000767E08087E760000060E7C780E0600004262725A4E460000007E7E4242000000060E1C38706000000042427E7E000000080C06060C080000404040404040000000060E0C00000000387C44443C7C00007F7F44447C380000387C44446C280000387C44447F7F0000387C54545C180000087E7F090B02000098BCA4A4FCF800007F7F04047C78000044447D7D404000008080FDFD000000007F7F081C7662000040417F7F404000787C0C180C7C7800007C7C08047C780000387C44447C380000FCFC48447C380000387C4448FCFC80007C7C08041C180000585C545474300000043E7E44440000003C7C40407C7C00001C3C70603C1C003C7C6030607C3C00006C7C10107C6C00009CBCA0A0FCFC00006474745C5C4C000000087E764200000000007E7E000000000042767E0800000010081818100800007E5A66665A7E00

]]