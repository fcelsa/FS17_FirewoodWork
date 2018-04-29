--
-- Firewood
--
-- @author fcelsa - TyKonKet
-- @date 28/04/2018

-- TODO: da togliere dopo aver sistemato la gui definitiva
function round(n, precision)
    if precision and precision > 0 then
        return math.floor((n * math.pow(10, precision)) + 0.5) / math.pow(10, precision)
    end
    return math.floor(n + 0.5)
end

local targetAspectRatio = 16 / 9 -- = 1920/1080;
local aspectRatioRatio = g_screenAspectRatio / targetAspectRatio
local sizeRatio = 1
if g_screenWidth > 1920 then
    sizeRatio = 1920 / g_screenWidth
elseif g_screenWidth < 1920 then
    sizeRatio = math.max((1920 / g_screenWidth) * .75, 1)
end

function getFullPx(n, dimension)
    if dimension == "x" then
        return round(n * g_screenWidth) / g_screenWidth
    else
        return round(n * g_screenHeight) / g_screenHeight
    end
end

-- px are in targetSize for 1920x1080
function pxToNormal(px, dimension, fullPixel)
    local ret
    if dimension == "x" then
        ret = (px / 1920) * sizeRatio
    else
        ret = (px / 1080) * sizeRatio * aspectRatioRatio
    end
    if fullPixel == nil or fullPixel then
        ret = getFullPx(ret, dimension)
    end
    return ret
end

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

    WoodSellTrigger.triggerCallback = Utils.appendedFunction(WoodSellTrigger.triggerCallback, self.firewoodSellTrigger)

    -- TODO: sistemazione delle variabili che effettivamente servono.
    self.palletFilename = Utils.getFilename("pallet/firewoodPallet.i3d", self.dir)
    self.baleFilename = Utils.getFilename("bales/firewoodpack.i3d", self.dir)
    self.guiScale = Utils.getNoNil(g_gameSettings:getValue("uiScale"), 1)
    self.fontSize = 0.014 * self.guiScale
    self.segaon = false
    self.metro = false
    self.misura = 0
    self.txtPezzi = ""
    self.lunPezzi = 0
    self.volPezzi = 0
    self.statString = " "
    self.econStringA = " "
    self.econStringB = " "
    self.barString = ""
    self.cutCNT = 0
    self.numCNT = 1
    self.pagLegna = 0
    self.customerRequest = 1
    self.flagGDMsg = false
    self.pineGrowing = false
    self.secTimer = 0
    self.flagSpawnPalletOk = 0

    --TODO: personalizzazione splitTypes da mettere in una funzione?
    self:print("Split types:")
    for _, s in pairs(SplitUtil.splitTypes) do
        self:print("name:%s splitType:%s pricePerLiter:%s woodChipsPerLiter:%s allowsWoodHarvester:%s", s.name, s.splitType, s.pricePerLiter, s.woodChipsPerLiter, s.allowsWoodHarvester)
    end

    SplitUtil.splitTypes[1].density = 0.47
    SplitUtil.splitTypes[2].density = 0.52
    SplitUtil.splitTypes[3].density = 0.59
    SplitUtil.splitTypes[4].density = 0.65
    SplitUtil.splitTypes[5].density = 0.69
    SplitUtil.splitTypes[6].density = 0.65
    SplitUtil.splitTypes[7].density = 0.67
    SplitUtil.splitTypes[8].density = 0.69
    SplitUtil.splitTypes[9].density = 0.73
    SplitUtil.splitTypes[10].density = 0.8
    SplitUtil.splitTypes[11].density = 0.48

    --name     type  $/l   chips/l allowHarvester
    --("spruce",   1,  0.7,    7.0,  true);  -- density 0.47
    --("pine",     2,  0.7,    7.0,  true);  -- density 0.52
    --("larch",    3,  0.7,    7.0,  true);  -- density 0.59
    --("birch",    4,  0.85,   7.2,  false); -- density 0.65
    --("beech",    5,  0.9,    7.4,  false); -- density 0.69
    --("maple",    6,  0.9,    7.4,  false); -- density 0.65
    --("oak",      7,  0.9,    7.4,  false); -- density 0.67
    --("ash",      8,  0.9,    7.4,  false); -- density 0.69
    --("locust",   9,  1.0,    7.8,  false); -- density 0.73
    --("mahogany", 10, 1.1,    8.0,  false); -- density 0.8
    --("poplar",   11, 0.7,    7.5,  false); -- density 0.48

    self.woodOverlay = createImageOverlay(Utils.getFilename("guis/legna.dds", self.dir))
    self.woodOverlayTime = 0
    self.bgOverlay = createImageOverlay("dataS2/menu/blank.png")
    setOverlayColor(self.bgOverlay, 0, 0, 0, 0.6)
    self.graphOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png")
    self.fweffectSample = createSample("fweffectSample")
    loadSample(self.fweffectSample, Utils.getFilename("sounds/fweffect.wav", self.dir), false)
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
    if self.fweffectSample then
        delete(self.fweffectSample)
    end
end

function Firewood:keyEvent(unicode, sym, modifier, isDown)
end

function Firewood:mouseEvent(posX, posY, isDown, isUp, button)
    -- init / azzeramento manuale del metro
    if isDown and button == 3 then
        if Input.isKeyPressed(Input.KEY_lshift) and self.segaon then
            local p = nil
            if g_currentMission.player ~= nil then
                p = g_currentMission.player.rootNode
            end
            self.misura = 0
            aX1, aY1, aZ1 = getWorldTranslation(p)
            g_currentMission:showBlinkingWarning(g_i18n:getText("FW_ZEROMT"), 2000)
            self.metro = not (self.metro)
        end
    end
end

function Firewood:update(dt)
    self.secTimer = self.secTimer + dt * 0.001

    local p = nil
    if g_currentMission.player ~= nil then
        p = g_currentMission.player.rootNode
        if g_currentMission.player.currentTool ~= nil then
            if g_currentMission.player.usesChainsaw then
                self.segaon = true
            end
        else
            self.segaon = false
        end
    end

    local cuttingOn = false
    local afterCutWait = false
    local horizontalCut = false
    local cutParticle = false
    if p ~= nil and self.segaon and g_currentMission.player.currentTool ~= nil then
        cuttingOn = g_currentMission.player.currentTool.isCutting
        afterCutWait = g_currentMission.player.currentTool.waitingForResetAfterCut
        horizontalCut = g_currentMission.player.currentTool.isHorizontalCut

        if g_currentMission.player.currentTool.particleSystems[1].isEmitting then
            cutParticle = true
        else
            cutParticle = false
        end

        if self.metro then
            -- coordinate player e calcolo metri.
            local bX, bY, bZ = getWorldTranslation(p)
            local c2 = (math.pow((aX1 - bX), 2) + math.pow((aZ1 - bZ), 2))
            self.misura = math.sqrt((c2 + math.abs((aY1 - bY), 2)))
            self.misura = math.floor(self.misura * 100 + 0.5) / 100
        end

        self.statString = g_i18n:getText("FW_LEGNA") .. " Kg " .. tostring(self.cutCNT)
        self.barString = tostring(math.floor((self.cutCNT / 1000) * 100)) .. "%"

        -- informazioni sui pezzi
        local shape = 0
        local pSpl = g_currentMission.player.currentTool.cutNode
        local x, y, z = getWorldTranslation(pSpl)
        local nx, ny, nz = localDirectionToWorld(pSpl, 1, 0, 0)
        local yx, yy, yz = localDirectionToWorld(pSpl, 0, 1, 0)
        local minY, maxY, minZ, maxZ
        shape, minY, maxY, minZ, maxZ = findSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, 1.1, 1)
        if shape ~= 0 and shape ~= nil then
            self.txtPezzi = ""
            splitType = SplitUtil.splitTypes[getSplitType(shape)]
            local chpMulti = splitType.woodChipsPerLiter -- quanto woodchip per litro
            local bdyPezzi = getRigidBodyType(shape) -- se è Static è un albero in piedi
            local volume = getVolume(shape) -- game engine volume
            local massa = getMass(shape) -- per l'albero in piedi torna sempre 1
            local qualityScale = 1
            local lengthScale = 1
            local defoliageScale = 1
            local sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(shape)
            if sizeX ~= nil and volume > 0 then
                local bvVolume = sizeX * sizeY * sizeZ
                local volumeRatio = bvVolume / volume
                local volumeQuality = 1 - math.sqrt(Utils.clamp((volumeRatio - 3) / 7, 0, 1)) * 0.95 --  ratio <= 3: 100%, ratio >= 10: 5%
                local convexityQuality = 1 - Utils.clamp((numConvexes - 2) / (6 - 2), 0, 1) * 0.95 -- 0-2: 100%:, >= 6: 5%

                local maxSize = math.max(sizeX, math.max(sizeY, sizeZ))
                -- 1m: 60%, 6-11m: 120%, 19m: 60%
                if maxSize < 11 then
                    lengthScale = 0.6 + math.min(math.max((maxSize - 1) / 5, 0), 1) * 0.6
                else
                    lengthScale = 1.2 - math.min(math.max((maxSize - 11) / 8, 0), 1) * 0.6
                end

                local minQuality = math.min(convexityQuality, volumeQuality)
                local maxQuality = math.max(convexityQuality, volumeQuality)
                qualityScale = minQuality + (maxQuality - minQuality) * 0.3 -- use 70% of min quality
                defoliageScale = 1 - math.min(numAttachments / 15, 1) * 0.8 -- #attachments 0: 100%, >=15: 20%
                local radius = ((maxY - minY) + (maxZ - minZ)) / 4
                local diameter = (2 * radius) * 1000
                local peso = volume * splitType.density

                self.txtPezzi = splitType.name .. string.format("  m. %02.1f", maxSize) .. string.format("  D mm %03d  ", diameter) .. "  Att." .. tostring(defoliageScale * 100) .. "%"
                self.txtPezzi = self.txtPezzi .. string.format("\n  vol %.2f ", volumeRatio) .. string.format("  conv %.2f ", convexityQuality) .. string.format("  ps %.2f ", peso)
                self.txtPezzi = self.txtPezzi .. string.format("  mc %3.2f ", volume)
                if g_currentMission.showHelpText and maxSize < 2.0 and maxSize > 0.1 and massa ~= 1 then
                    g_currentMission:addHelpButtonText(g_i18n:getText("FW_QSLICE"), InputBinding.FW_QSLICE)
                end

                local ckInput = true
                if InputBinding.hasEvent(InputBinding.FW_QSLICE, true) then
                    if numAttachments ~= 0 and shape ~= 0 and not horizontalCut then
                        removeSplitShapeAttachments(shape, x, y, z, nx, ny, nz, yx, yy, yz, 10000, 10000, 10000)
                        ckInput = false
                    else
                        ckInput = true
                    end

                    if Input.isKeyPressed(Input.KEY_lshift) and bdyPezzi == "Static" then
                        bdyPezzi = " " -- trucco per mettere via anche i ceppi che normalmente non voglio far sparire... salvo che il ceppo sia in terra per oltre 2 metri...
                    end

                    if Input.isKeyPressed(Input.KEY_lshift) and bdyPezzi ~= "Static" then
                        self.cutCNT = self.cutCNT + math.floor(volume * 1000)
                        self.deleteSlice(shape)
                        playSample(self.fweffectSample, 3, 1, 0)
                        ckInput = false
                    else
                        ckInput = true
                    end

                    if maxSize <= 1.0 and bdyPezzi ~= "Static" and ckInput then
                        self.cutCNT = self.cutCNT + math.floor(volume * 1000)
                        self.deleteSlice(shape)
                        playSample(self.fweffectSample, 1, 1, 0)
                    end

                    if maxSize > 1.6 and ckInput then
                        local x, y, z = getWorldTranslation(g_currentMission.player.currentTool.cutNode)
                        local nx, ny, nz = localDirectionToWorld(g_currentMission.player.currentTool.cutNode, 1, 0, 0)
                        local yx, yy, yz = localDirectionToWorld(g_currentMission.player.currentTool.cutNode, 0, 1, 0)
                        ChainsawUtil.cutSplitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, 1, 1)
                    end
                end

                -- spruce piantato che sta crescendo, però se è meno di 2.2 probabilmente è un ceppo.
                if volume < 3 and splitType.splitType == 1 and horizontalCut and maxSize > 2.2 and massa == 1 and bdyPezzi == "Static" then
                    self.pineGrowing = true
                else
                    self.pineGrowing = false
                end
            end
            if self.txtPezzi ~= "" then
                --Utils.renderTextAtWorldPosition(x, y, z, self.txtPezzi, getCorrectTextSize(0.02), 0);
                --Utils.renderTextAtWorldPosition(x+1, y, z, self.txtPezzi, getCorrectTextSize(0.02), 0);
                self.renderTxtWP(x, y, z, self.txtPezzi, getCorrectTextSize(0.020), 0)

                -- debug
                renderText(0.01, 0.01, self.fontSize, ("%.3f"):format(maxZ) .. "  <-->  " .. ("%.3f"):format(minZ) .. "  x:" .. ("%.3f"):format(x) .. "  y:" .. ("%.3f"):format(y) .. "  z:" .. ("%.3f"):format(z) .. "  ")
            end
        else
            self.txtPezzi = ""
        end
        ----------------------

        -- tagli orizzontali, normalmente abbattimento del tronco
        if horizontalCut and afterCutWait and shape ~= 0 then
            -- quando finisce di tagliare dovrebbe calcolare l'addimpulse per farlo cadere sicuro...
            local impulsePerTon = 4
            local objectMass = getMass(shape)
            local impulse = math.sqrt(impulsePerTon * objectMass)
            local partX, partZ = -math.sin(maxY), -math.cos(maxY)
            local partSum = math.abs(partX) + math.abs(partZ)
            local impulseX = impulse * partX / partSum
            local impulseY = impulse * 0.1
            local impulseZ = impulse * partZ / partSum
            addImpulse(shape, impulseX, impulseY, impulseZ, x, y, z, false)
        end

        -- delimb...
        if cutParticle and not (cuttingOn) then
            if math.random(10) > 7 then
                self.cutCNT = self.cutCNT + 1
            end
        end

        -- cut
        if cuttingOn and cutParticle then
            if math.random(10) > 5 then
                self.cutCNT = self.cutCNT + 1
            end
        end

        -- azzero la misura dopo la fine di un taglio e reimposto la posizione
        if afterCutWait then
            self.misura = 0
            self.metro = true
            aX1, aY1, aZ1 = getWorldTranslation(p)
        end

        if self.cutCNT >= 1000 then
            local eccedenza = self.cutCNT - 1000
            self.numCNT = self.numCNT + 1
            self.cutCNT = eccedenza
            eccedenza = 0
        end

        --if Input.isKeyPressed(Input.KEY_r) and self.numCNT >= 2 then
        if InputBinding.hasEvent(InputBinding.FW_SELLFW) and self.numCNT >= 2 then
            if Input.isKeyPressed(Input.KEY_lshift) then
                self.numCNT = self.numCNT - 1
                self:createWoodPack(1000)
            else
                self.numCNT = self.numCNT - 1
                self:createWoodPallet(2000)
            end
        end
    end

    if self.woodOverlayTime > 0 then
        self.woodOverlayTime = self.woodOverlayTime - dt
    end

    if g_currentMission.showHelpText and self.numCNT >= 2 then
        g_currentMission:addHelpButtonText(g_i18n:getText("FW_SELLFW"), InputBinding.FW_SELLFW)
    end
end

function Firewood:draw()
    local povlX = g_currentMission.weatherForecastBgOverlay.x
    local povlY = g_currentMission.weatherForecastBgOverlay.y - 0.22
    local wdth = pxToNormal(176, "x")
    local hgth = pxToNormal(176, "y")

    if g_currentMission.renderTime and g_currentMission.player.currentTool ~= nil then
        renderOverlay(self.bgOverlay, povlX, povlY, (wdth * 2) + 0.010, hgth + 0.010)
        renderOverlay(self.woodOverlay, povlX, povlY, wdth, hgth)
        setTextColor(0.95, 0.95, 0.95, 1)
        renderText(povlX + 0.10, povlY + 0.140, self.fontSize, self.econStringA .. " ")

        if self.txtPezzi ~= "" then
            setTextColor(0.95, 0.95, 0.95, 1)
            renderText(povlX + 0.07, povlY + 0.158, self.fontSize, self.txtPezzi)
            self.resetSetRendOpt()
        end

        if self.segaon then
            renderText(povlX + 0.008, povlY + 0.01, self.fontSize, self.statString)
            local packBar = Utils.clamp((self.cutCNT / 1000), 0, 1)
            if packBar > 1 then
                packBar = 1
            end
            self.resetSetRendOpt()

            if packBar <= 0.70 then
                setOverlayColor(self.graphOverlay, 0, 1, 0.5, 0.5)
            end
            if packBar >= 0.75 then
                setOverlayColor(self.graphOverlay, 0.55, 0.55, 0, 0.5)
            end
            if packBar >= 0.85 then
                setOverlayColor(self.graphOverlay, 1, 0.55, 0, 0.5)
            end
            if packBar >= 0.95 then
                setOverlayColor(self.graphOverlay, 1, 0, 0, 0.5)
            end
            renderOverlay(self.graphOverlay, povlX + 0.09, povlY + 0.034, 0.009, packBar / 10)
            renderText(povlX + 0.09, povlY + 0.02, self.fontSize, "pallet # " .. tostring(self.numCNT))

            -- debug
            -- renderText(0.01, 0.01, self.fontSize, ("%.3f"):format(aX1).."  "..("%.3f"):format(aY1).."  "..("%.3f"):format(aZ1).." sx:"..("%.3f"):format(sx).."  sy:"..("%.3f"):format(sy).."  ");
            -- renderText(0.01, 0.01, 0.014, "On:"..tostring(self.cutOn).." Hz:"..tostring(self.cutHz).."  Dl:"..tostring(self.cutDl).."  St:"..tostring(self.cutSt).."  segaon:"..tostring(self.segaon).."  "..self.txtPezzi.."  "..self.secTimer);
            if self.txtPezzi ~= "" then
                local x, y, z = getWorldTranslation(g_currentMission.player.currentTool.cutNode)
                local nx, ny, nz = localDirectionToWorld(g_currentMission.player.currentTool.cutNode, 1, 0, 0)
                local yx, yy, yz = localDirectionToWorld(g_currentMission.player.currentTool.cutNode, 0, 1, 0)
                drawDebugLine(nx, ny, nx, 1, 0, 0, yx, yy, yz, 1, 0, 0)
            end
        end

        if self.woodOverlayTime > 0 then
            renderText(povlX + 0.09, povlY + 0.11, self.fontSize, self.econStringB)
        end
        if self.metro then
            setTextColor(0, 0, 0, 1)
            renderText(0.55, 0.12, 0.022, " m. " .. ("%.2f"):format(self.misura))
            setTextColor(1, 0, 0, 1)
            renderText(0.55, 0.12, 0.022, " _ _ _ _ _ _ _ _ ")
            self.resetSetRendOpt()
            setOverlayColor(self.graphOverlay, 1, 0.93, 0, 0.4)
            renderOverlay(self.graphOverlay, 0.548, 0.115, 0.075, 0.0325)
        end
        self.resetSetRendOpt()
    end
end

-----------------------------------------------------------------------------
-- funzioni specifiche
-----------------------------------------------------------------------------
function Firewood.resetSetRendOpt()
    -- reset settaggi testo a beneficio delle altre mod
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    setTextBold(false)
end

function Firewood.renderTxtWP(x, y, z, text, textSize, textOffset)
    local sx, sy, sz = project(x, y, z)
    if sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1 then
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextBold(true)
        setTextColor(0.0, 0.0, 1.0, 0.70)
        renderText(sx, sy - 0.0018 + textOffset, textSize, text)
        setTextColor(0.5, 1.0, 0.7, 1.0)
        renderText(sx, sy + textOffset, textSize, text)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end

function Firewood.deleteSlice(shape)
    if shape ~= nil and shape ~= 0 then
        if g_currentMission:getIsServer() then
            delete(shape)
        else
            g_client:getServerConnection():sendEvent(firewoodShapeEvent:new(shape))
        end
    end
end

function Firewood:createWoodPack(fillLevel)
    -- TODO: sincronizzare in MP
    if g_currentMission:getIsServer() and g_currentMission.controlPlayer and g_currentMission.player ~= nil and g_currentMission.player.isControlled and g_currentMission.player.rootNode ~= nil and g_currentMission.player.rootNode ~= 0 then
        local x, y, z = getWorldTranslation(g_currentMission.player.rootNode)
        local dirX = -math.sin(g_currentMission.player.rotY)
        local dirZ = -math.cos(g_currentMission.player.rotY)
        x = x + dirX * 4
        z = z + dirZ * 4
        y = y + 5
        local woodPackObject = WoodPack:new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
        woodPackObject:load(self.baleFilename, x, y, z, 0, 0, 0, nil)
        woodPackObject:register()
        self:print("woodPackObject created at  %s  %s  %s", x, y, z)
    end
end

function Firewood:createWoodPallet(fillLevel)
    -- TODO: sincronizzare in MP
    if g_currentMission:getIsServer() and g_currentMission.controlPlayer and g_currentMission.player ~= nil and g_currentMission.player.isControlled and g_currentMission.player.rootNode ~= nil and g_currentMission.player.rootNode ~= 0 then
        local x, y, z = getWorldTranslation(g_currentMission.player.rootNode)
        local dirX = -math.sin(g_currentMission.player.rotY)
        local dirZ = -math.cos(g_currentMission.player.rotY)
        x = x + dirX * 4
        z = z + dirZ * 4
        y = y + 5
        local fillableWoodPalletObject = FillableWoodPallet:new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
        fillableWoodPalletObject:load(self.palletFilename, x, y, z, 0, 0, 0, nil)
        fillableWoodPalletObject:register()
        self:print("fillableWoodPalletObject created at  %s  %s  %s", x, y, z)
    end
end

function Firewood:firewoodSellTrigger(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    -- TODO: effettuare vendita della balla o pallet
    Firewood:print("firewoodSellTrigger, triggerId: %s  otherActorId: %s  onEnter: %s  onLeave: %s  onStay: %s  otherShapeId: %s", triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if self.isEnabled and onEnter and otherActorId ~= 0 then
        local object = g_currentMission:getNodeObject(otherActorId)
        if object ~= nil then
            if object:isa(WoodPack) or object:isa(FillableWoodPallet) then
                playSample(g_currentMission.cashRegistrySound, 1, 1, 0)
                if g_currentMission:getIsServer() then
                    local difficultyMultiplier = g_currentMission.missionInfo.sellPriceMultiplier
                    local baseValue = object:getValue()
                    local money = baseValue * difficultyMultiplier
                    g_currentMission:addSharedMoney(money, "soldBales")
                    g_currentMission:addMoneyChange(money, FSBaseMission.MONEY_TYPE_SINGLE, true, g_i18n:getText("FW_finance_soldWoodPack"))
                    object:delete()
                end
            end
        end
    end
end

addModEventListener(Firewood)
