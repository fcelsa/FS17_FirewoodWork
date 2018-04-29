--
-- Firewood
--
-- @author fcelsa - TyKonKet
-- @date 28/04/2018

WoodPack = {}

WoodPack_mt = Class(WoodPack, Bale)

InitObjectClass(WoodPack, "WoodPack")

function WoodPack:new(isServer, isClient, customMt)
    local mt = customMt
    if mt == nil then
        mt = WoodPack_mt
    end
    local self = Bale:new(isServer, isClient, mt)
    --self:setFillLevel(fillLevel)
    registerObjectClassName(self, "WoodPack")
    return self
end

function WoodPack:getValue()
    local multiplier = 1
    local temperature = math.floor((g_currentMission.environment.weatherTemperaturesDay[1] + g_currentMission.environment.weatherTemperaturesNight[1]) / 2)
    if temperature <= 14 then
        multiplier = multiplier * 1.15
    end
    if temperature <= 5 then
        multiplier = multiplier * 1.15
    end
    local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(self.fillType) * multiplier
    return self.fillLevel * pricePerLiter * self.baleValueScale
end
