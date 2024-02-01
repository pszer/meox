-- clips a triangle to be within [-1,1]^3 cube

__CLIP_TRIANGLE_VERT_ATTS=3

function clipTriangleAxisPlane(tri,axis,value,dir)
	local tri1=tri[1]
	local tri2=tri[2]
	local tri3=tri[3]

	local function interp(p,v,t)
		local V={}
		for i=1,__CLIP_TRIANGLE_VERT_ATTS do
			V[i]=p[i] + t*(v[i]-p[i])
		end
		return V
	end

	if dir>0 then
		local ok1,ok2,ok3 =
		 tri1[axis] >= value,
		 tri2[axis] >= value,
		 tri3[axis] >= value

		-- case 0 vert outside
		if ok1 and ok2 and ok3 then return tri, nil end
		-- case 3 vert outside
		if not (ok1 or ok2 or ok3) then return nil, nil end

		--
		-- cases 2 vert outside
		if ok1 and not ok2 and not ok3 then
			local p = tri1
			local t2 = (p[axis]-value) / -(tri2[axis]-p[axis])
			local t3 = (p[axis]-value) / -(tri3[axis]-p[axis])
			return {
				(p),
				interp(p,tri2,t2),
				interp(p,tri3,t3),
			},nil
		end
		if not ok1 and ok2 and not ok3 then
			local p = tri2
			local t1 = (p[axis]-value) / -(tri1[axis]-p[axis])
			local t3 = (p[axis]-value) / -(tri3[axis]-p[axis])
			return {
				interp(p,tri1,t1),
				(p),
				interp(p,tri3,t3),
			},nil
		end
		if not ok1 and not ok2 and ok3 then
			local p = tri3
			local t1 = (p[axis]-value) / -(tri1[axis]-p[axis])
			local t2 = (p[axis]-value) / -(tri2[axis]-p[axis])
			return {
				interp(p,tri1,t1),
				interp(p,tri2,t2),
				(p),
			},nil
		end

		-- 
		-- cases 1 verts outside
		if ok1 and ok2 and not ok3 then
			local p = tri3
			local t1 = (tri1[axis]-value) / (tri1[axis]-p[axis])
			local t2 = (tri2[axis]-value) / (tri2[axis]-p[axis])
			local p1 = interp(tri1,p,t1)
			local p2 = interp(tri2,p,t2)
			return {
				(tri1),
				(tri2),
				p1
			},{
				(tri2),
				p2,
				p1,}
		end
		if ok1 and not ok2 and ok3 then
			local p = tri2
			local t1 = (tri1[axis]-value) / (tri1[axis]-p[axis])
			local t3 = (tri3[axis]-value) / (tri3[axis]-p[axis])
			local p1 = interp(tri1,p,t1)
			local p3 = interp(tri3,p,t3)
			return {
				(tri1),
				p1,
				(tri3),
			},{
				(tri3),
				p1,
				p3,}
		end
		if not ok1 and ok2 and ok3 then
			local p = tri1
			local t2 = (tri2[axis]-value) / (tri2[axis]-p[axis])
			local t3 = (tri3[axis]-value) / (tri3[axis]-p[axis])
			local p2 = interp(tri2,p,t2)
			local p3 = interp(tri3,p,t3)
			return {
				p2,
				(tri2),
				(tri3)
			},{
				(tri3),
				p3,
				p2,}
		end
	else
		local ok1,ok2,ok3 =
		 tri1[axis] <= value,
		 tri2[axis] <= value,
		 tri3[axis] <= value

		-- case 0 vert outside
		if ok1 and ok2 and ok3 then return tri, nil end
		-- case 3 vert outside
		if not (ok1 or ok2 or ok3) then return nil, nil end

		--
		-- cases 2 vert outside
		if ok1 and not ok2 and not ok3 then
			local p = tri1
			local t2 = (p[axis]-value) / -(tri2[axis]-p[axis])
			local t3 = (p[axis]-value) / -(tri3[axis]-p[axis])
			return {
				(p),
				interp(p,tri2,t2),
				interp(p,tri3,t3),
			},nil
		end
		if not ok1 and ok2 and not ok3 then
			local p = tri2
			local t1 = (p[axis]-value) / -(tri1[axis]-p[axis])
			local t3 = (p[axis]-value) / -(tri3[axis]-p[axis])
			return {
				interp(p,tri1,t1),
				(p),
				interp(p,tri3,t3),
			},nil
		end
		if not ok1 and not ok2 and ok3 then
			local p = tri3
			local t1 = (p[axis]-value) / -(tri1[axis]-p[axis])
			local t2 = (p[axis]-value) / -(tri2[axis]-p[axis])
			return {
				interp(p,tri1,t1),
				interp(p,tri2,t2),
				(p),
			},nil
		end

		-- 
		-- cases 1 verts outside
		if ok1 and ok2 and not ok3 then
			local p = tri3
			local t1 = (tri1[axis]-value) / (tri1[axis]-p[axis])
			local t2 = (tri2[axis]-value) / (tri2[axis]-p[axis])
			local p1 = interp(tri1,p,t1)
			local p2 = interp(tri2,p,t2)
			return {
				(tri1),
				(tri2),
				p1
			},{
				(tri2),
				p2,
				p1,}
		end
		if ok1 and not ok2 and ok3 then
			local p = tri2
			local t1 = (tri1[axis]-value) / (tri1[axis]-p[axis])
			local t3 = (tri3[axis]-value) / (tri3[axis]-p[axis])
			local p1 = interp(tri1,p,t1)
			local p3 = interp(tri3,p,t3)
			return {
				(tri1),
				p1,
				(tri3),
			},{
				(tri3),
				p1,
				p3,}
		end
		if not ok1 and ok2 and ok3 then
			local p = tri1
			local t2 = (tri2[axis]-value) / (tri2[axis]-p[axis])
			local t3 = (tri3[axis]-value) / (tri3[axis]-p[axis])
			local p2 = interp(tri2,p,t2)
			local p3 = interp(tri3,p,t3)
			return {
				p2,
				(tri2),
				(tri3)
			},{
				(tri3),
				p3,
				p2,}
		end
	end
end

return function (triangle)
	local function isInsideRegion(i)
			return triangle[1][i] >= -1 and triangle[1][i] <= 1 and
			       triangle[2][i] >= -1 and triangle[2][i] <= 1 and
						 triangle[3][i] >= -1 and triangle[3][i] <= 1 
	end

	local inX = isInsideRegion(1)
	local inY = isInsideRegion(2)
	local inZ = isInsideRegion(3)

	if inX and inY and inZ then return {triangle} end
	if not (inX or inY or inZ) then return {} end

	local clippedTriangles={}
	clippedTriangles[1]=triangle
	if not inX then
		-- -x
		do
			local new_tris={}
			for i,v in ipairs(clippedTriangles) do
				local a,b = clipTriangleAxisPlane(v,1,-1,1)
				if a then table.insert(new_tris,a) end
				if b then table.insert(new_tris,b) end
			end
			clippedTriangles=new_tris
		end

		-- +x
		do
			local new_tris={}
			for i,v in ipairs(clippedTriangles) do
				local a,b = clipTriangleAxisPlane(v,1,1,-1)
				if a then table.insert(new_tris,a) end
				if b then table.insert(new_tris,b) end
			end
			clippedTriangles=new_tris
		end
	end
	
	if not inY then
		-- -y
		do
			local new_tris={}
			for i,v in ipairs(clippedTriangles) do
				local a,b = clipTriangleAxisPlane(v,2,-1,1)
				if a then table.insert(new_tris,a) end
				if b then table.insert(new_tris,b) end
			end
			clippedTriangles=new_tris
		end

		-- +y
		do
			local new_tris={}
			for i,v in ipairs(clippedTriangles) do
				local a,b = clipTriangleAxisPlane(v,2,1,-1)
				if a then table.insert(new_tris,a) end
				if b then table.insert(new_tris,b) end
			end
			clippedTriangles=new_tris
		end
	end

	if not inZ then
	-- -z
		do
			local new_tris={}
			for i,v in ipairs(clippedTriangles) do
				local a,b = clipTriangleAxisPlane(v,3,-1,1)
				if a then table.insert(new_tris,a) end
				if b then table.insert(new_tris,b) end
			end
			clippedTriangles=new_tris
		end

		-- +z
		do
			local new_tris={}
			for i,v in ipairs(clippedTriangles) do
				local a,b = clipTriangleAxisPlane(v,3,1,-1)
				if a then table.insert(new_tris,a) end
				if b then table.insert(new_tris,b) end
			end
			clippedTriangles=new_tris
		end
	end

	return clippedTriangles
end
