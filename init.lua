--[[ Mycroft language
]]--
for _,module in ipairs({"mycBuiltins.lua","mycCore.lua","mycErr.lua","mycNet.lua","mycParse.lua","mycPretty.lua","mycTests.lua","mycType.lua"}) do
	require("mycroft."..module)
end


