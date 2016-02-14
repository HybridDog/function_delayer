-- abort if the function already exists
if minetest.delay_function then
	return
end

local load_time_start = os.clock()

local maxdelay = 1
local skipstep = 5


-- used for the table.sort function
local function sort_times(a,b)
	return a[1] < b[1]
end

local needs_sort
local todo = {}
function minetest.delay_function(time, func, ...)
	todo[#todo+1] = {time, func, {...}}

	needs_sort = true
end

local stepnum = 0
local col_dtime = 0
minetest.register_globalstep(function(dtime)
	local count = #todo

	-- abort if nothing is todo
	if count == 0 then
		return
	end

	-- abort if it's not the skipstepths step
	stepnum = (stepnum+1)%skipstep
	col_dtime = col_dtime+dtime
	if stepnum ~= 0 then
		return
	end
	dtime = col_dtime
	col_dtime = 0

	-- get the start time
	local ts = tonumber(os.clock())-dtime

	if needs_sort then
		-- execute the functions with lower delays earlier
		table.sort(todo, sort_times)
		needs_sort = false
	end

	-- execute expired functions
	local n = 1
	while true do
		if not todo[n] then
			break
		end
		local time = todo[n][1]
		time = time-dtime
		if time <= 0 then
			local params = todo[n][3] or {}
			params[#params+1] = time
			local func = todo[n][2]
			table.remove(todo, n)
			func(unpack(params))
		else
			todo[n][1] = time
			n = n+1
		end
	end

	-- abort if too much time is used already
	if tonumber(os.clock())-ts > maxdelay then
		return
	end

	-- execute functions until the time limit is reached
	while true do
		if not todo[1] then
			return
		end
		local params = todo[1][3] or {}
		params[#params+1] = todo[1][1]
		local func = todo[1][2]
		table.remove(todo, 1)
		func(unpack(params))
		if tonumber(os.clock())-ts > maxdelay then
			return
		end
	end
end)

local time = math.floor(tonumber(os.clock()-load_time_start)*100+0.5)/100
local msg = "[function_delayer] loaded after ca. "..time
if time > 0.05 then
	print(msg)
else
	minetest.log("info", msg)
end
