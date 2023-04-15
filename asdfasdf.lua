_G.require = require

local spring = require("./spring")

-- local mySpring = spring.New(3,18,80,50,0,0)
local mySpring = spring.New(3,18,80,0,0,0)

mySpring:InitResolver()
-- mySpring:SetOffset(50,5)
-- mySpring:AddVelocity(5)
-- mySpring:SetVelocity(5)
mySpring:SetGoal(5)
-- mySpring:SetOffset(5)
-- mySpring:SetVelocity(10000)
-- mySpring:SetGoal(10000)
local timer = require("timer")
timer.setTimeout(100,function()
    -- mySpring:SetVelocity(0)
    -- mySpring:SetOffset(50)
    mySpring:SetVelocity(0)
end)
-- timer.setTimeout(5000,mySpring.SetVelocity,mySpring,10)

while true do
    timer.sleep(100)
    print(mySpring:GetOffset())
end


