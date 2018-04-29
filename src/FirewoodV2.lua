--
-- Firewood
--
-- @author fcelsa - TyKonKet
-- @date 28/04/2018

Firewood = {}
Firewood.name = "Firewood"
Firewood.debug = true
Firewood.dir = g_currentModDirectory

function Firewood:print(text, ...)
    if self.debug then
        local start = string.format("%s[%s] -> ", self.name, getDate("%H:%M:%S"))
        local ptext = string.format(text, ...)
        print(string.format("%s%s", start, ptext))
    end
end

function Firewood:initialize(missionInfo, missionDynamicInfo, loadingScreen)
    self = Firewood
    self:print("Firewood:initialize(%s, %s, %s)", missionInfo, missionDynamicInfo, loadingScreen)
end
g_mpLoadingScreen.loadFunction = Utils.prependedFunction(g_mpLoadingScreen.loadFunction, Firewood.initialize)

function Firewood:load(missionInfo, missionDynamicInfo, loadingScreen)
    self = Firewood
    self:print("Firewood:load(%s, %s, %s)", missionInfo, missionDynamicInfo, loadingScreen)
    g_currentMission.loadMapFinished = Utils.appendedFunction(g_currentMission.loadMapFinished, self.loadMapFinished)
    g_currentMission.onStartMission = Utils.appendedFunction(g_currentMission.onStartMission, self.afterLoad)
    g_currentMission.missionInfo.saveToXML = Utils.appendedFunction(g_currentMission.missionInfo.saveToXML, self.saveSavegame)
end
g_mpLoadingScreen.loadFunction = Utils.appendedFunction(g_mpLoadingScreen.loadFunction, Firewood.load)

function Firewood:loadMap(name)
    self:print("Firewood:loadMap(%s)", name)
    self:loadSavegame()
end

function Firewood:loadMapFinished()
    self = Firewood
    self:print("Firewood:loadMapFinished()")
end

function Firewood:afterLoad()
    self = Firewood
    self:print("Firewood:afterLoad()")
end

function Firewood:onStartMission()
    self = Firewood
    self:print("Firewood:onStartMission()") 
end
g_mpLoadingScreen.buttonOkPC.onClickCallback = Utils.appendedFunction(g_mpLoadingScreen.buttonOkPC.onClickCallback, Firewood.onStartMission)

function Firewood:loadSavegame()
    self:print("Firewood:loadSavegame()")
    if g_server ~= nil then
    end
end

function Firewood:saveSavegame()
    self = Firewood
    self:print("Firewood:saveSavegame()")
    if g_server ~= nil then
    end
end

function Firewood:deleteMap()
    self:print("Firewood:deleteMap()")
end

function Firewood:keyEvent(unicode, sym, modifier, isDown)
end

function Firewood:mouseEvent(posX, posY, isDown, isUp, button)
end

function Firewood:update(dt)
end

function Firewood:draw()
end

addModEventListener(Firewood)
