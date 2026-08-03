--- @meta regkex

--- @class Regkex
--- @overload fun(pattrn: string, flags?: string): Regkex
local Regkex = {}

--- @alias Regkex.Replacer fun(str: string, ...string): string

--- @param str         string
--- @param replacement string|Regkex.Replacer
--- @param offset?     integer
--- @return string
function Regkex:gsub(str, replacement, offset) end

return Regkex
