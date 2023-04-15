local module = {}

local smoothCam = require(script.smoothCam)
local managed = nil

local userInputService = game:GetService("UserInputService")

function module.init(isTesting)
    if managed then
        error("Inited aready")
    end
    managed = smoothCam.New(nil,isTesting or false)
    -- managed.LeftX = 7/4*math.pi
    -- managed.RightX = math.pi/4
    managed:Resume()
    -- managed.PositionOverwrite = Vector3.new(-23.100000381469727, 0.5000039935112, 58.04999923706055)

    local toggle = false
    userInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if input.KeyCode == Enum.KeyCode.E then
            toggle = not toggle
            if toggle then
                managed:SetLeftRight(game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame,math.pi/4,math.pi/4)
            else
                managed:ResetLeftRight()
            end
        end
    end)

    if isTesting then
        print("Reloaded!")
        managed:SetLeftRight(workspace.TestPlayer.HumanoidRootPart.CFrame,math.pi/4,math.pi/4)
    end
end

function module.deinit()
    if not managed then
        error("Not inited")
    end
    managed:Destroy()
    managed = nil
end

return module
