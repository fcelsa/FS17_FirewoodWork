--
-- Firewood
--
-- @author fcelsa - TyKonKet
-- @date 28/04/2018

FillableWoodPallet = {}

FillableWoodPallet_mt = Class(FillableWoodPallet, FillablePallet)

InitObjectClass(FillableWoodPallet, "FillableWoodPallet")

function FillableWoodPallet:new(isServer, isClient, customMt)
    local mt = customMt
    if mt == nil then
        mt = FillableWoodPallet_mt
    end
    local self = FillablePallet:new(isServer, isClient, mt)
    --self:setFillLevel(fillLevel)
    registerObjectClassName(self, "FillableWoodPallet")
    return self
end

function FillableWoodPallet:getValue()
    local multiplier = 1
    local temperature = math.floor((g_currentMission.environment.weatherTemperaturesDay[1] + g_currentMission.environment.weatherTemperaturesNight[1]) / 2)
    if temperature <= 14 then
        multiplier = multiplier * 1.15
    end
    if temperature <= 5 then
        multiplier = multiplier * 1.15
    end
    local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(self.fillType) * multiplier
    return self.fillLevel * pricePerLiter * self.fillablePalletValueScale
end
