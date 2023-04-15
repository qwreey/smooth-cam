
local spring = require(script.Parent.spring) ---@module src.spring
local maid = require(script.Parent.maid) ---@module src.maid

local Player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local smoothCam = {}
smoothCam.__index = smoothCam

local clamp = math.clamp

function smoothCam:GetPosition()
    if self.IsTesting then
        local HumanoidRootPart = workspace.TestPlayer.HumanoidRootPart
        return HumanoidRootPart.Position + (HumanoidRootPart.CFrame.UpVector*(HumanoidRootPart.Size.Y/2 + 0.5))
    end
    local Character = Player.Character
    local HumanoidRootPart = Character and Character.HumanoidRootPart
    local Head = Character and Character.Head
    if not HumanoidRootPart then return end
    return HumanoidRootPart.Position + (HumanoidRootPart.CFrame.UpVector*(HumanoidRootPart.Size.Y/2 + (Head and Head.Size.Y/2 or 0)))
end

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

local DoublePI = math.pi*2
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

function smoothCam.New(Camera:Camera?,isTesting:boolean?): smoothCam
    Camera = Camera or workspace.CurrentCamera

    local taskMaid = maid.New()
    local this = {
        Camera = Camera;
        TaskMaid = taskMaid;
        IsEnabled = false;
        Sensitivity = 0.002;
        Shiver = 0.46;
        MaxY=defaultMaxY;
        MinY=-defaultMaxY;
        LeftX=nil,RightX=nil;
        ShiverSpring = {5,58,230,0,0,0};
        IsTesting = isTesting;
        RotationSpring = {5,832,20000,0,0,0};
    }
    setmetatable(this,smoothCam)

    return this
end

function smoothCam:Pause()
    if not self.IsEnabled then error("Pause cannnot be called when not enabled") end
    self.IsEnabled = false
    self.TaskMaid:Clean()

    -- .유저 인풋 상태를 복구함
    if Player then
        Player.CameraMode = self.LastCameraMode
    end
    self.Camera.CameraType = self.LastCameraType
    UserInputService.MouseBehavior = self.LastMouseBehavior
    UserInputService.MouseIconEnabled = self.LastMouseIconEnabled
end

-- 왼쪽 오른쪽 넘어간거 다시 원상복구
function smoothCam:CalculateLeftRight(GoalX,UserInput)
    local RightX = self.RightX
    local LeftX = self.LeftX

    -- 오른쪽 각이 왼쪽 각보다 큰 경우
    if RightX and LeftX and (UserInput ~= 0) then
        local IsRightBigger = RightX > LeftX
        -- 방향 값이 넘어간 경우 (재조정이 필요한 경우)
        if (IsRightBigger and (LeftX>GoalX or RightX<GoalX)) or ((not IsRightBigger) and (GoalX<LeftX and GoalX>RightX)) then
            return (UserInput > 0) and RightX or LeftX, true
        end
    end
    return GoalX, false
end

function smoothCam:Resume()
    if self.IsEnabled then error("Resume cannnot be called when enabled") end
    self.IsEnabled = true

    -- 지금의 유저 인풋과 카메라 상태를 저장함
    self.LastCameraMode = Player and Player.CameraMode
    self.LastCameraType = self.Camera.CameraType
    self.LastMouseBehavior = UserInputService.MouseBehavior
    self.LastMouseIconEnabled = UserInputService.MouseIconEnabled
    -- 인풋 상태를 지정함
    if Player then
        Player.CameraMode = Enum.CameraMode.LockFirstPerson
    end
    self.Camera.CameraType = Enum.CameraType.Scriptable
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    local springX = spring.New(unpack(self.RotationSpring)):InitResolver()
    local springY = spring.New(unpack(self.RotationSpring)):InitResolver()
    local springZ = spring.New(unpack(self.ShiverSpring)):InitResolver()

    local initY,initX,initZ = self.Camera.CFrame:ToEulerAnglesYXZ()
    springX:SetGoal(initX)
    springY:SetGoal(initY)
    springZ:SetGoal(initZ)
    self.springX = springX
    self.springY = springY
    self.springZ = springZ

    -- 캠 움직임 처리
    if self.IsTesting then
        self.TaskMaid:AddTask(RunService.RenderStepped:Connect(function()
            local position = self.PositionOverwrite or self:GetPosition()
            if not position then return end

            self.Camera.CFrame = CFrame.fromEulerAnglesYXZ(springY:GetOffset(),springX:GetOffset(),springZ:GetOffset())+position
        end))
    else
        RunService:BindToRenderStep("CamInit", Enum.RenderPriority.Camera.Value+1,function()
            local position = self.PositionOverwrite or self:GetPosition()
            if not position then return end

            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            UserInputService.MouseIconEnabled = false

            self.Camera.CFrame = CFrame.fromEulerAnglesYXZ(springY:GetOffset(),springX:GetOffset(),springZ:GetOffset())+position
        end)
        self.TaskMaid:AddTask(function()
            RunService:UnbindFromRenderStep("CamInit")
        end)
    end

    -- 인풋 처리
    self.TaskMaid:AddTask(UserInputService.InputChanged:Connect(function(Input:InputObject)
        if Input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local Sensitivity = self.Sensitivity

        local UserInput = - Input.Delta.X * Sensitivity
        local GoalX = springX:GetGoal() + UserInput
        local lastOffset,LastVelocity,over

        if GoalX > DoublePI then
            lastOffset = GoalX-springX:GetOffset() -- 지금의 위치를 지금의(넘어버린) 골에 대해서 상대적으로 저장을 합니다
            GoalX,over = self:CalculateLeftRight(GoalX % DoublePI,UserInput) -- 골을 다시 일반각으로 변환합니다 (동경을 다시 360 도 내로 옮김)
            if lastOffset > 0 and over then
                lastOffset = 0
            end
            springX:SetGoal(GoalX) -- 골을 지정합니다
            springX:SetOffset(GoalX-lastOffset) -- 상대적으로 저장한 오프셋을 불러옵니다
        elseif GoalX < 0 then
            LastVelocity = springX:GetVelocity()
            GoalX = self:CalculateLeftRight(DoublePI - ((-GoalX)%DoublePI),UserInput)
            springX:SetGoal(GoalX)
            springX:SetVelocity(LastVelocity)
        else
            springX:SetGoal(self:CalculateLeftRight(GoalX,UserInput))
        end

        springY:SetGoal( clamp(springY:GetGoal() - Input.Delta.Y * Sensitivity,self.MinY,self.MaxY) )
        springZ:AddVelocity(-Input.Delta.X * self.Shiver * Sensitivity)
    end))
end

function smoothCam:Destroy()
    self:Pause()
    if Player then
        Player.CameraMode = self.LastCameraMode
    end
    self.Camera.CameraType = self.LastCameraType
end

-- lookX 에 대해서 좌우 제한을 겁니다.
function smoothCam:SetLeftRight(cframe,leftOffset,rightOffset)
    local X = select(2,cframe:ToEulerAnglesYXZ())
    self.LeftX = (X-leftOffset)%DoublePI
    self.RightX = (X+rightOffset)%DoublePI
end

function smoothCam:ResetLeftRight()
    self.LeftX = nil
    self.RightX = nil
end

return smoothCam
