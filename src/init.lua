local module = {}

local smoothCam = require(script.smoothCam)
local managed = nil

function module.init()
    if managed then
        error("Inited aready")
    end
    managed = smoothCam.New()
    managed:Resume()
    -- managed.PositionOverwrite = Vector3.new(-23.100000381469727, 0.5000039935112, 58.04999923706055)
end

function module.deinit()
    if not managed then
        error("Not inited")
    end
    managed:Destroy()
    managed = nil
end

return module
