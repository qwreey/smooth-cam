
local spring = require(script.Parent.spring) ---@module src.spring
local maid = require(script.Parent.maid) ---@module src.maid

local Player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local smoothCam = {}
smoothCam.__index = smoothCam

local clamp = math.clamp

function smoothCam.GetPosition()
    local Character = Player.Character
    local HumanoidRootPart = Character and Character.HumanoidRootPart
    local Head = Character and Character.Head
    if not HumanoidRootPart then return end
    return HumanoidRootPart.Position + (HumanoidRootPart.CFrame.UpVector*(HumanoidRootPart.Size.Y/2 + (Head and Head.Size.Y/2 or 0)))
end
local GetPosition = smoothCam.GetPosition

-- SAMPLE
-- local ShiverSpring = {3,18,80,0,0,0}
-- local ShiverSpring = {5,24,40,0,0,0}
-- local ShiverSpring = {5,60,280,0,0,0}
-- local ShiverSpring = {5,70,300,0,0,0}
-- local ShiverSpring = {5,55,180,0,0,0}
-- local RotationYSpring = {5,1000,20000,0,0,0}
-- local RotationYSpring = {2,30,60,0,0,0}
-- local RotationXSpring = {2,30,60,0,0,0}
-- ShiverSpring = {5,55,180,0,0,0};
-- ShiverSpring = {5,60,250,0,0,0};

local halfPI = math.pi/2
local defaultMaxY = halfPI-math.rad(15)

export type smoothCam = {
    Sensitivity: number;
    Shiver: number;
    MaxY: number;
    MinY: number;
    ShiverSpring: typeof({5 :: number,58 :: number,230 :: number,0 :: number,0 :: number,0 :: number});
    RotationSpring: typeof({5 :: number,832 :: number,20000 :: number,0 :: number,0 :: number,0 :: number});

    Pause: (self:smoothCam)->();
    Resume: (self:smoothCam)->();
    Destroy: (self:smoothCam)->();
}

function smoothCam.New(Camera:Camera?): smoothCam
    Camera = Camera or workspace.CurrentCamera

    local taskMaid = maid.New()
    local this = {
        LastCameraMode = Player.CameraMode;
        LastCameraType = Camera.CameraType;
        Camera = Camera;
        TaskMaid = taskMaid;
        IsEnabled = false;
        Sensitivity = 0.002;
        Shiver = 0.46;
        MaxY=defaultMaxY;
        MinY=-defaultMaxY;
        MinX=nil,MaxX=nil,OffsetX=nil,OffsetY=nil;
        ShiverSpring = {5,58,230,0,0,0};
        RotationSpring = {5,832,20000,0,0,0};
    }
    setmetatable(this,smoothCam)

    Player.CameraMode = Enum.CameraMode.LockFirstPerson
    Camera.CameraType = Enum.CameraType.Scriptable
    game.StarterPlayer.CameraMaxZoomDistance = 0

    return this
end

function smoothCam:Pause()
    if not self.IsEnabled then error("Pause cannnot be called when not enabled") end
    self.IsEnabled = false
    self.TaskMaid:Clean()
end

function smoothCam:Resume()
    if self.IsEnabled then error("Resume cannnot be called when enabled") end
    self.IsEnabled = true

    local springX = spring.New(unpack(self.RotationSpring)):InitResolver()
    local springY = spring.New(unpack(self.RotationSpring)):InitResolver()
    local springZ = spring.New(unpack(self.ShiverSpring)):InitResolver()

    local initY,initX,initZ = self.Camera.CFrame:ToEulerAnglesYXZ()
    springX:SetGoal(initX)
    springY:SetGoal(initY)
    springZ:SetGoal(initZ)

    self.TaskMaid:AddTask(RunService.RenderStepped:Connect(function()
        local position = self.PositionOverwrite or GetPosition()
        if not position then return end

        self.Camera.CFrame = CFrame.fromEulerAnglesYXZ(springY:GetOffset(),springX:GetOffset(),springZ:GetOffset())+position
    end))
    self.TaskMaid:AddTask(UserInputService.InputChanged:Connect(function(Input:InputObject)
        if Input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local Sensitivity = self.Sensitivity
        -- springX:SetGoal( (springX:GetGoal() + Input.Delta.X * Sensitivity + 1)%2 - 1 )
        -- MinX=nil,MinY=nil,MaxX=nil,MaxY=nil,OffsetX=nil,OffsetY=nil

        -- springX:GetOffset()
        -- springX:GetVelocity()
        -- springX:AddVelocity()
        -- springX:SetOffset()

        springX:SetGoal( springX:GetGoal() - Input.Delta.X * Sensitivity )
        springY:SetGoal( clamp(springY:GetGoal() - Input.Delta.Y * Sensitivity,self.MinY,self.MaxY) )
        springZ:AddVelocity(-Input.Delta.X * self.Shiver * Sensitivity)
    end))
end

function smoothCam:Destroy()
    self:Pause()
    Player.CameraMode = self.LastCameraMode
    self.Camera.CameraType = self.LastCameraType
end

return smoothCam
