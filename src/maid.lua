
local maid = {}
maid.__index = maid
local insert = table.insert

function maid.New()
    return setmetatable({},maid)
end

function maid:AddTask(task)
    insert(self,task)
end

function maid:Clean()
    for index,object in pairs(self) do
        if typeof(object) == "RBXScriptConnection" then
            object:Disconnect()
            object:Destroy()
        end
        self[index] = nil
    end
end

return maid
