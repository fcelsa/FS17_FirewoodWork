--
-- Firewood
--
-- @author fcelsa - TyKonKet
-- @date 24/04/2018

firewoodShapeEvent = {}
firewoodShapeEvent_mt = Class(firewoodShapeEvent, Event)
InitEventClass(firewoodShapeEvent, "firewoodShapeEvent")
function firewoodShapeEvent:emptyNew()
    local self = Event:new(firewoodShapeEvent_mt)
    self.className = "firewoodShapeEvent"
    return self
end

function firewoodShapeEvent:new(shape)
    local self = firewoodShapeEvent:emptyNew()
    self.shape = shape
    return self
end

function firewoodShapeEvent:writeStream(streamId, connection)
    -- print(tostring(g_currentMission.time).. "ms - firewoodShapeEvent:writeStream(streamId, connection)");
    writeSplitShapeIdToStream(streamId, self.shape)
end

function firewoodShapeEvent:readStream(streamId, connection)
    -- print(tostring(g_currentMission.time).. "ms - firewoodShapeEvent:readStream(streamId, connection)");
    self.shape = readSplitShapeIdFromStream(streamId)
    self:run(connection)
end

function firewoodShapeEvent:run(connection)
    if self.shape ~= nil and self.shape ~= 0 then
        Firewood.deleteSlice(self.shape)
    end
end
