-- abort if the function already exists
if minetest.delay_function then
	return
end

local load_time_start = os.clock()

local maxdelay = 0.5


-- used for the table.sort function
local function sort_times(a,b)
	return a[1] < b[1]
end

local todo = {}
function minetest.delay_function(time, func, ...)
	table.insert(todo, {time, func, {...}})

	-- execute the functions with lower delays earlier
	table.sort(todo, sort_times)
end

minetest.register_globalstep(function(dtime)
	local count = #todo

	-- abort if nothing is todo
	if count == 0 then
		return
	end

	-- get the start time
	local ts = tonumber(os.clock())-dtime

	-- execute expired functions
	local n = 1
	while n <= count do
		local time = todo[n][1]
		time = time-dtime
		if time <= 0 then
			local params = todo[n][3]
			params[#params+1] = time
			todo[n][2](unpack(params or {}))
			table.remove(todo, n)
			count = count-1
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
	n = 1
	while n <= count do
		local params = todo[n][3]
		params[#params+1] = todo[n][1]
		todo[n][2](unpack(params or {}))
		table.remove(todo, n)
		count = count-1
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
