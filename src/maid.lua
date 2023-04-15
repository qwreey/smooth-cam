
local maid = {}
maid.__index = maid
local insert = table.insert

function maid.New()
    return setmetatable({},maid)
end

function maid:AddTask(task)
    insert(self,task)
end

local function Get(ins,key)
    return ins[key]
end
local function PcallGet(ins,key)
    local ok,result = pcall(Get,ins,key)
    if ok then
        return result
    end
end

function maid:Clean()
    for index,object in pairs(self) do
        if type(object) == "function" then
            object()
        else
            do
                local fn = PcallGet(object,"Disconnect")
                if fn then
                    fn(object)
                end
            end
            do
                local fn = PcallGet(object,"Destroy")
                if fn then
                    fn(object)
                end
            end
        end
        self[index] = nil
    end
end

return maid
