local string_format = string.format
local string_match = string.match
local tonumber = tonumber
local tup = tup
local tup_definerule = tup.definerule

do
	local commands = {
		linux = function(input, position, output)
			return string_format("( cat -- %s && echo TRACKNUMBER=%i ) > %s", input, position, output)
		end,
		win32 = function(input, position, output)
			return string_format("( type %s && echo TRACKNUMBER=%i ) > %s", input, position, output)
		end,
	}
	
	local command = commands[tup.getconfig("TUP_PLATFORM")] or commands.linux
	
	local album_tag_files = tup.glob("*.tags-album.vc")
	local i = 1
	local album_tag_file = album_tag_files[1]
	while album_tag_file do
		local basename = string_match(album_tag_file, "^(%d+%-[^.]+)%.tags%-album%.vc$")
		local position = tonumber(string_match(album_tag_file, "^(%d+)%-[^.]+%.tags%-album%.vc$"))
		local output = basename .. ".tags.vc"
		
		tup_definerule{
			inputs = {
				album_tag_file,
			},
			command = string_format("^ GENTAG %s^ %s", basename, command(album_tag_file, position, output)),
			outputs = {
				output,
			},
		}
		
		i = i + 1
		album_tag_file = album_tag_files[i]
	end
end

vibes.process_directory()
