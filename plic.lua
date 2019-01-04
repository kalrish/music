-- PlayList Item Compiler

local io_open
local io_close
local io_write
do
	local io = io
	io_open = io.open
	io_close = io.close
	io_write = io.write
end
local string_match = string.match
local tonumber = tonumber

local load_plitem = function(path)
	local fd = io_open(path, "rb")
	local content = fd:read("a")
	io_close(fd)
	local filename, position = string_match(content, "^(.+)%-(%d+)%s*$")
	return filename, tonumber(position)
end

local load_plitems = function(paths)
	local tracks = {}
	
	local i = 1
	local path = paths[1]
	repeat
		local pathdir = string_match(path, "^(.+)/[^/]+$")
		local filename, position = load_plitem(path)
		tracks[position] = pathdir .. "/" .. filename
		
		i = i + 1
		path = paths[i]
	until path == nil
	
	return tracks
end

local write_tracklist = function(tracks)
	local i = 1
	local track = tracks[1]
	repeat
		io_write(track, "\n")
		
		i = i + 1
		track = tracks[i]
	until track == nil
end

local plitemc = function(paths)
	local tracks = load_plitems(paths)
	write_tracklist(tracks)
end

plitemc(arg)
