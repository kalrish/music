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
					
					tup_definerule{
						inputs = rulespec.inputs,
						command = "^ ENCODE " .. basename .. "^ " .. rulespec.command,
						outputs = {
							rulespec.output,
						},
					}
				end
			end
		else
			error("CONFIG_ENCODER not set")
		end
	end,
}
