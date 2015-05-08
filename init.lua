--[[ Mycroft language
]]--
for _,module in ipairs({"mycBuiltins","mycCore","mycErr","mycNet","mycParse","mycPretty","mycTests","mycType"}) do
	package.preload[module]=function() return require("mycroft."..module) end
end
for _,module in ipairs({"mycBuiltins","mycCore","mycErr","mycNet","mycParse","mycPretty","mycTests","mycType"}) do
	require("mycroft."..module)
end


