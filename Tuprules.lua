local
	io_close,
	io_open
do
	local io = io
	io_close = io.close
	io_open = io.open
end
local setmetatable = setmetatable
local string = string
local string_format = string.format
local string_gmatch = string.gmatch
local string_rep = string.rep
local table_concat = table.concat
local tup = tup
local tup_append_table = tup.append_table
local tup_base = tup.base
local tup_definerule = tup.definerule
local tup_getconfig = tup.getconfig
local tup_glob = tup.glob

tup.creategitignore()

local CONFIG_TUP_PLATFORM = tup_getconfig("TUP_PLATFORM")

local top_dir = tup.getcwd()

local getconfig_default = function(name, default)
	local value = tup_getconfig(name)
	if value ~= "" then
		return value
	else
		return default
	end
end

local options_defaults = {
	encode = true,
}
local load_options = function(name)
	local options = {}
	
	local file = io_open(name, "r")
	if file then
		for line in file:lines() do
			local key, sign, post = line:match("^(%l+)([%+%-=])(.*)$")
			local value
			if sign == "-" then
				value = false
			elseif sign == "+" then
				value = true
			elseif sign == "=" then
				value = post
			else
				value = nil
			end
			options[key] = value
		end
		io_close(file)
	end
	
	return options
end

local encoders = {}
do
	do
		local flac = {
			input_extensions = {
				"aiff",
				"flac",
				"oga",
				"ogg",
				"raw",
				"wav",
				"wave",
			},
			flac_program = getconfig_default("FLAC", "flac"),
			flac_options = tup_getconfig("FLAC_FLAGS"),
			metaflac_program = getconfig_default("METAFLAC", "metaflac"),
			metaflac_options = tup_getconfig("METAFLAC_FLAGS"),
			format = getconfig_default("FORMAT", "flac"),
		}
		
		local format2extension = {
			flac = "flac",
			oggflac = "oga",
		}
		
		function flac:encode(basename, input, options)
			local tagfile = basename .. ".tags.vc"
			local inputs = {
				input,
				tagfile,
			}
			local output = basename .. "." .. format2extension[self.format]
			
			local import_picture_args
			local options_apic = options.apic
			if options_apic then
				import_picture_args = {}
				
				local i = 1
				for apic_type, format, dir in string_gmatch(options_apic, "(%d%d?):(%l+):?([^;]*);?") do
					if dir == "" then
						dir = "."
					end
					
					import_picture_args[i*2-1] = "--picture"
					import_picture_args[i*2] = string_format("\"%s||||%s/picture-%02i.%s\"", apic_type, dir, apic_type, format)
					i = i + 1
				end
				
				import_picture_args = table_concat(import_picture_args, " ")
			else
				import_picture_args = ""
			end
			
			local import_tags_args = {}
			do
				local tag_files = self.tag_files
				
				tup_append_table(inputs, tag_files)
				
				local i = 1
				local tag_file = tag_files[1]
				while tag_file do
					import_tags_args[i*2-1] = "--import-tags-from"
					import_tags_args[i*2] = tag_file
					
					i = i + 1
					tag_file = tag_files[i]
				end
			end
			import_tags_args = table_concat(import_tags_args, " ")
			
			return {
				inputs = inputs,
				command = string_format(
					"%s %s %s -o %s -- %s && %s %s --import-tags-from %s %s %s",
					self.flac_program,
					self.flac_options,
					import_picture_args,
					output,
					input,
					self.metaflac_program,
					self.metaflac_options,
					tagfile,
					import_tags_args,
					output
				),
				output = output,
			}
		end
		
		local metatable = {
			__metatable = true,
			__index = flac,
		}
		
		function encoders.flac()
			local obj = {}
			
			local depth_level
			do
				local _
				_, depth_level = string.gsub(top_dir, "%.%.", "")
			end
			
			local tag_files = {}
			for i = 0, depth_level do
				local tag_file = string_rep("../", i) .. "tags.vc"
				tag_files[i+1] = tag_file
			end
			obj.tag_files = tag_files
			
			setmetatable(obj, metatable)
			
			return obj
		end
	end
	
	do
		local lame = {
			input_extensions = {
				"aiff",
				"raw",
				"wav",
				"wave",
			},
			lame_program = getconfig_default("LAME", "lame"),
			lame_options = tup_getconfig("LAME_OPTIONS"),
		}
		
		function lame:encode(basename, input)
			local output = basename .. ".mp3"
			return {
				inputs = {
					input
				},
				command = self.encoder .. " " .. self.lame_program .. " " .. self.lame_options .. " " .. input .. " " .. output,
				output = output,
			}
		end
		
		local metatable = {
			__metatable = true,
			__index = lame,
		}
		
		function encoders.lame()
			return setmetatable({}, metatable)
		end
	end
	
	do
		local oggenc = {
			input_extensions = {
				"aiff",
				"flac",
				"oga",
				"ogg",
				"raw",
				"wav",
				"wave",
			},
			oggenc_program = getconfig_default("OGGENC", "oggenc"),
			oggenc_options = tup_getconfig("OGGENC_FLAGS"),
		}
		
		function oggenc:encode(basename, input)
			local output = basename .. ".ogg"
			-- FIXME: support tagging
			-- 
			-- oggvorbis = {
			-- 	program = "vorbiscomment",
			-- 	tag = function(tagger, tagger_options, output_untagged, tag_files, output_tagged)
			-- 		local inputs = {
			-- 			output_untagged
			-- 		}
			-- 		
			-- 		tup_append_table(inputs, tag_files)
			-- 		
			-- 		return {
			-- 			inputs = inputs,
			-- 			command = "cat -- " .. table_concat(tag_files, " ") .. " | " .. tagger .. " -w " .. tagger_options .. " -c - -- " .. output_untagged .. " " .. output_tagged,
			-- 			outputs = { output_tagged }
			-- 		}
			-- 	end,
			-- 	tagfiles_extension = "vc"
			-- }
			-- END
			return {
				inputs = {
					input
				},
				command = self.oggenc_program .. " " .. self.oggenc_options .. " -o " .. output .. " -- " .. input,
				output = output,
			}
		end
		
		local metatable = {
			__metatable = true,
			__index = oggenc,
		}
		
		function encoders.oggenc()
			return setmetatable({}, metatable)
		end
	end
end

local playlist_formats = {}
do
	local i = 1
	for playlist_format in string_gmatch(tup_getconfig("PLAYLISTS"), "([^,]+)") do
		playlist_formats[i] = playlist_format
		i = i + 1
	end
end

local playlisters = {}
do
end

vibes = {
	process_directory = function()
		local CONFIG_ENCODER = tup_getconfig("ENCODER")
		if CONFIG_ENCODER ~= "" then
			local options_directory = load_options("vibes.txt")
			local options_directory = setmetatable(
				load_options("vibes.txt"),
				{
					__metatable = true,
					__index = options_defaults,
				}
			)
			
			local encoder = encoders[CONFIG_ENCODER]()
			
			local sources = {}
			do
				local options_metatable_files = {
					__metatable = true,
					__index = options_directory,
				}
				
				local input_extensions = encoder.input_extensions
				
				local i = 1
				local input_extension = input_extensions[1]
				repeat
					local matches = tup_glob("*." .. input_extension)
					do
						local j = 1
						local match = matches[1]
						while match do
							sources[match] = setmetatable(load_options(tup_base(match) .. ".vibes.txt"), options_metatable_files)
							
							j = j + 1
							match = matches[j]
						end
					end
					
					i = i + 1
					input_extension = input_extensions[i]
				until input_extension == nil
			end
			
			for source, options in pairs(sources) do
				if options.encode then
					local basename = tup_base(source)
					
					local rulespec = encoder:encode(basename, source, options)
					
					local outputs = {
						rulespec.output,
					}
					
					if options.playlists then
						for playlist, position in string_gmatch(options.playlists, "([^,]+):(%d+)") do
							local plitem = string_format("%s.%s.plitem", basename, playlist)
							tup_definerule{
								command = string_format("^ PLITEM %s %s^ echo %s-%s > %s", basename, playlist, rulespec.output, position, plitem),
								outputs = {
									plitem,
									string_format("%s/<plitems-%s>", top_dir, playlist),
								},
							}
						end
					end
					
					tup_definerule{
						inputs = rulespec.inputs,
						command = "^ ENCODE " .. basename .. "^ " .. rulespec.command,
						outputs = outputs,
					}
				end
			end
		else
			error("CONFIG_ENCODER not set")
		end
	end,
	generate_playlist = function(name)
		local compiled = name .. ".playlist"
		
		tup_definerule{
			inputs = {
				"<plitems-" .. name .. ">",
			},
			command = string_format("^ PLITEMC %s^ lua53 -- plitemc.lua %%<plitems-%s> > %s", name, name, compiled),
			outputs = {
				compiled,
			},
		}
		
		local i = 1
		local format = playlist_formats[1]
		while format do
			local rulespec = playlisters[format](name, compiled)
			
			tup_definerule{
				inputs = {
					compiled,
				},
				command = string_format("^ PLAYLIST-%s %s^ %s", format, name, rulespec.command),
				outputs = {
					rulespec.output,
					"<playlist-" .. name .. ">",
				},
			}
			
			i = i + 1
			format = playlist_formats[i]
		end
	end,
}
