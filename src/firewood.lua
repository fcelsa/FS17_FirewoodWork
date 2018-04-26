--
-- firewood 17
--
-- by @fcelsa
--
--
-- 02/2017: 1.0.0.17  -  lavoro a prima versione funzionante per FS17

local function round(n, precision)
    if precision and precision > 0 then
        return math.floor((n * math.pow(10, precision)) + 0.5) / math.pow(10, precision);
    end
    return math.floor(n + 0.5);
end

local targetAspectRatio = 16 / 9; -- = 1920/1080;
local aspectRatioRatio = g_screenAspectRatio / targetAspectRatio;
local sizeRatio = 1;
if g_screenWidth > 1920 then
    sizeRatio = 1920 / g_screenWidth;
elseif g_screenWidth < 1920 then
    sizeRatio = math.max((1920 / g_screenWidth) * .75, 1);
end

local function getFullPx(n, dimension)
    if dimension == 'x' then
        return round(n * g_screenWidth) / g_screenWidth;
    else
        return round(n * g_screenHeight) / g_screenHeight;
    end
end

-- px are in targetSize for 1920x1080
local function pxToNormal(px, dimension, fullPixel)
    local ret;
    if dimension == 'x' then
        ret = (px / 1920) * sizeRatio;
    else
        ret = (px / 1080) * sizeRatio * aspectRatioRatio;
    end;
    if fullPixel == nil or fullPixel then
        ret = getFullPx(ret, dimension);
    end;
    return ret;
end

firewood = {};

local modItem = ModsUtil.findModItemByModName(g_currentModName);
firewood.version = (modItem and modItem.version) and modItem.version or "?.?.?";
firewood.dir = g_currentModDirectory;

addModEventListener(firewood);

-----------------------------------------------------------------------------
-- funzioni specifiche
-----------------------------------------------------------------------------
function firewood.resetSetRendOpt()
    -- reset settaggi testo a beneficio delle altre mod
    setTextAlignment(RenderText.ALIGN_LEFT);
    setTextColor(1, 1, 1, 1);
    setTextBold(false);
end

function firewood.renderTxtWP(x, y, z, text, textSize, textOffset)
    local sx, sy, sz = project(x, y, z);
    if sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1 then
        setTextAlignment(RenderText.ALIGN_CENTER);
        setTextBold(true);
        setTextColor(0.0, 0.0, 1.0, 0.70);
        renderText(sx, sy - 0.0018 + textOffset, textSize, text);
        setTextColor(0.5, 1.0, 0.7, 1.0);
        renderText(sx, sy + textOffset, textSize, text);
        setTextAlignment(RenderText.ALIGN_LEFT);
    end
end


function firewood.getFirewoodPrice()
    -- il prezzo base della legna è hardcoded
    local przLegna = math.floor(360 / g_currentMission.missionInfo.difficulty);
    -- aumenta il prezzo se la temperatura media della giornata è 14 o meno gradi
    local temperature = math.floor((g_currentMission.environment.weatherTemperaturesDay[1] + g_currentMission.environment.weatherTemperaturesNight[1]) / 2);
    if temperature <= 14 then
        przLegna = math.floor(przLegna + (przLegna * (0.30 / g_currentMission.missionInfo.difficulty)));
    end
    return przLegna;
end


function firewood:deleteSlice(shape)
    if g_currentMission:getIsServer() and shape ~= nil and shape ~= 0 then
        delete(shape);
    else
        g_client:getServerConnection():sendEvent(firewoodShapeEvent:new(shape));
    end
end

function firewood:createWoodPack()
    if g_currentMission:getIsServer() then
        local fillType = Utils.getNoNil(fillType, "straw");
        if FillUtil.fillTypeNameToInt[fillType] == nil then
            return
        end
        local bale = BaleUtil.getBale(FillUtil.fillTypeNameToInt[fillType], 1.22, nil, nil, 1.01, true);
        local realFile = Utils.convertFromNetworkFilename(bale.filename);
        local x,y,z = 0,0,0;
        local dirX, dirZ = 1,0;
        print("firewood: createWoodPack");
        if g_currentMission.controlPlayer then
            print("firewood: createWoodPack controPlayer");
            if g_currentMission.player ~= nil and g_currentMission.player.isControlled and g_currentMission.player.rootNode ~= nil and g_currentMission.player.rootNode ~= 0 then
                x, y, z = getWorldTranslation(g_currentMission.player.rootNode);
                dirX, dirZ = -math.sin(g_currentMission.player.rotY), -math.cos(g_currentMission.player.rotY);
                x,z = x+dirX*4, z+dirZ*4;
                y = y + 5;
                local baleObject = Bale:new(g_currentMission:getIsServer(), g_currentMission:getIsClient());
                baleObject:load(realFile, x,y,z,0,0,0, nil);
                baleObject:register();
                print("firewood: createWoodPack " .. tostring(x) .. " " .. tostring(y) .. tostring(z));
            end
        end
    end
end

-----------------------------------------------------------------------------
function firewood:loadMap(name)
    g_currentMission.firewoodBase = self;
    
    self.guiScale = Utils.getNoNil(g_gameSettings:getValue("uiScale"), 1)
    self.fontSize = 0.014 * self.guiScale;
    
    self.segaon = false;
    self.cutOn = false;
    self.cutSt = false;
    self.cutHz = false;
    self.cutDl = false;
    self.metro = false;
    self.misura = 0;
    self.txtPezzi = "";
    self.lunPezzi = 0;
    self.volPezzi = 0;
    self.statString = " ";
    self.econStringA = " ";
    self.econStringB = " ";
    self.barString = "";
    self.cutCNT = 0;
    self.numCNT = 1;
    self.pagLegna = 0;
    self.customerRequest = 1;
    self.flagGDMsg = false;
    self.pineGrowing = false;
    self.secTimer = 0;
    self.flagSpawnPalletOk = 0;
    
    for i = 1, #SplitUtil.splitTypes do
        print("firewood debug: " .. SplitUtil.splitTypes[i].name .. "  " .. SplitUtil.splitTypes[i].pricePerLiter);
        table.insert(SplitUtil.splitTypes[i], density);
    -- DebugUtil.printTableRecursively(SplitUtil.splitTypes[i],".",0,1);
    end
    
    SplitUtil.splitTypes[1].density = 0.47;
    SplitUtil.splitTypes[2].density = 0.52;
    SplitUtil.splitTypes[3].density = 0.59;
    SplitUtil.splitTypes[4].density = 0.65;
    SplitUtil.splitTypes[5].density = 0.69;
    SplitUtil.splitTypes[6].density = 0.65;
    SplitUtil.splitTypes[7].density = 0.67;
    SplitUtil.splitTypes[8].density = 0.69;
    SplitUtil.splitTypes[9].density = 0.73;
    SplitUtil.splitTypes[10].density = 0.8;
    SplitUtil.splitTypes[11].density = 0.48;
    
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
    self.woodOverlay = createImageOverlay(Utils.getFilename("legna.dds", firewood.dir));
    self.woodOverlayTime = 0;
    self.bgOverlay = createImageOverlay("dataS2/menu/blank.png");
    setOverlayColor(self.bgOverlay, 0, 0, 0, 0.6);
    self.graphOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png");
    self.fweffectSample = createSample("fweffectSample");
    loadSample(self.fweffectSample, Utils.getFilename("sounds/fweffect.wav", firewood.dir), false);

end

function firewood:deleteMap()
    if self.fweffectSample then
        delete(self.fweffectSample);
    end
end

function firewood:mouseEvent(posX, posY, isDown, isUp, button)
    
    -- init / azzeramento manuale del metro
    if isDown and button == 3 then
        if Input.isKeyPressed(Input.KEY_lshift) and self.segaon then
            local p = nil;
            if g_currentMission.player ~= nil then
                p = g_currentMission.player.rootNode;
            end;
            self.misura = 0;
            aX1, aY1, aZ1 = getWorldTranslation(p);
            g_currentMission:showBlinkingWarning(g_i18n:getText("FW_ZEROMT"), 2000);
            self.metro = not (self.metro);
        end
    end

end

function firewood:keyEvent(unicode, sym, modifier, isDown)
end

function firewood:update(dt)
    --if g_client == nil then return; end;
    if g_currentMission.paused then return; end;
    self.secTimer = self.secTimer + dt * 0.001;
    
    local p = nil;
    if g_currentMission.player ~= nil then
        p = g_currentMission.player.rootNode;
        
        if g_currentMission.player.currentTool ~= nil then
            if g_currentMission.player.usesChainsaw then
                self.segaon = true;
            end
        else
            self.segaon = false;
        end
    end
    
    
    local pagLegna = firewood.getFirewoodPrice()
    self.econStringA = g_i18n:getText('FW_PREZZO') .. (' %s '):format(g_i18n:formatMoney(pagLegna, 0, true)) .. " / t.";
    if self.customerRequest ~= 1 then
        self.econStringA = self.econStringA .. " (x" .. tostring(self.customerRequest) .. ") ";
    end
    
    if p ~= nil and self.segaon and g_currentMission.player.currentTool ~= nil then
        
        self.cutOn = g_currentMission.player.currentTool.isCutting;
        self.cutSt = g_currentMission.player.currentTool.waitingForResetAfterCut;
        self.cutHz = g_currentMission.player.currentTool.isHorizontalCut;
        
        if g_currentMission.player.currentTool.particleSystems[1].isEmitting then
            self.cutDl = true;
        else
            self.cutDl = false;
        end
        
        if self.metro then
            -- coordinate player e calcolo metri.
            local bX, bY, bZ = getWorldTranslation(p);
            local c2 = (math.pow((aX1 - bX), 2) + math.pow((aZ1 - bZ), 2));
            self.misura = math.sqrt((c2 + math.abs((aY1 - bY), 2)));
            self.misura = math.floor(self.misura * 100 + 0.5) / 100;
        end
    
        self.statString = g_i18n:getText('FW_LEGNA') .. " Kg " .. tostring(self.cutCNT);
        self.barString = tostring(math.floor((self.cutCNT / 1000) * 100)) .. "%";
        
        -- informazioni sui pezzi
        local shape = 0;
        local pSpl = g_currentMission.player.currentTool.cutNode;
        local x, y, z = getWorldTranslation(pSpl);
        local nx, ny, nz = localDirectionToWorld(pSpl, 1, 0, 0);
        local yx, yy, yz = localDirectionToWorld(pSpl, 0, 1, 0);
        local minY, maxY, minZ, maxZ;
        shape, minY, maxY, minZ, maxZ = findSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, 1.1, 1);
        if shape ~= 0 and shape ~= nil then
            self.txtPezzi = "";
            splitType = SplitUtil.splitTypes[getSplitType(shape)];
            local chpMulti = splitType.woodChipsPerLiter -- quanto woodchip per litro
            local bdyPezzi = getRigidBodyType(shape)-- se è Static è un albero in piedi.
            local volume = getVolume(shape); -- game engine volume
            local massa = getMass(shape); -- per l'albero in piedi torna sempre 1
            local qualityScale = 1;
            local lengthScale = 1;
            local defoliageScale = 1;
            local sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(shape);
            if sizeX ~= nil and volume > 0 then
                local bvVolume = sizeX * sizeY * sizeZ;
                local volumeRatio = bvVolume / volume;
                local volumeQuality = 1 - math.sqrt(Utils.clamp((volumeRatio - 3) / 7, 0, 1)) * 0.95; --  ratio <= 3: 100%, ratio >= 10: 5%
                local convexityQuality = 1 - Utils.clamp((numConvexes - 2) / (6 - 2), 0, 1) * 0.95 -- 0-2: 100%:, >= 6: 5%
                
                local maxSize = math.max(sizeX, math.max(sizeY, sizeZ));
                -- 1m: 60%, 6-11m: 120%, 19m: 60%
                if maxSize < 11 then
                    lengthScale = 0.6 + math.min(math.max((maxSize - 1) / 5, 0), 1) * 0.6;
                else
                    lengthScale = 1.2 - math.min(math.max((maxSize - 11) / 8, 0), 1) * 0.6;
                end
                
                local minQuality = math.min(convexityQuality, volumeQuality);
                local maxQuality = math.max(convexityQuality, volumeQuality);
                qualityScale = minQuality + (maxQuality - minQuality) * 0.3; -- use 70% of min quality
                defoliageScale = 1 - math.min(numAttachments / 15, 1) * 0.8; -- #attachments 0: 100%, >=15: 20%
                local radius = ((maxY - minY) + (maxZ - minZ)) / 4;
                local diameter = (2 * radius) * 1000;
                local peso = volume * splitType.density;
                
                self.txtPezzi = splitType.name .. string.format("  m. %02.1f", maxSize) .. string.format("  D mm %03d  ", diameter) .. "  Att." .. tostring(defoliageScale * 100) .. "%";
                self.txtPezzi = self.txtPezzi .. string.format("\n  vol %.2f ", volumeRatio) .. string.format("  conv %.2f ", convexityQuality) .. string.format("  ps %.2f ", peso);
                self.txtPezzi = self.txtPezzi .. string.format("  mc %3.2f ", volume);
                if g_currentMission.showHelpText and maxSize < 2.0 and maxSize > 0.1 and massa ~= 1 then
                    g_currentMission:addHelpButtonText(g_i18n:getText("FW_QSLICE"), InputBinding.FW_QSLICE);
                end
                
                local ckInput = true;
                if InputBinding.hasEvent(InputBinding.FW_QSLICE, true) then
                    
                    if numAttachments ~= 0 and shape ~= 0 and not self.cutHz then
                        removeSplitShapeAttachments(shape, x, y, z, nx, ny, nz, yx, yy, yz, 10000, 10000, 10000);
                        ckInput = false;
						print(tostring(numConvexes));
                    else
                        ckInput = true;
                    end
                    
                    if Input.isKeyPressed(Input.KEY_lshift) and bdyPezzi == "Static" then
                        bdyPezzi = " "; -- trucco per mettere via anche i ceppi che normalmente non voglio far sparire... salvo che il ceppo sia in terra per oltre 2 metri...
                    end
                    
                    if Input.isKeyPressed(Input.KEY_lshift) and bdyPezzi ~= "Static" then
                        self.cutCNT = self.cutCNT + math.floor(volume * 1000);
                        self:deleteSlice(shape);
                        playSample(self.fweffectSample, 3, 1, 0);
						ckInput = false;
					else
						ckInput = true;
                    end
                    
                    if maxSize <= 1.0 and bdyPezzi ~= "Static" and ckInput then
                        self.cutCNT = self.cutCNT + math.floor(volume * 1000);
                        self:deleteSlice(shape);
                        playSample(self.fweffectSample, 1, 1, 0);
                    end
                    
                    if maxSize > 1.0 and ckInput then
                        local x, y, z = getWorldTranslation(g_currentMission.player.currentTool.cutNode);
                        local nx, ny, nz = localDirectionToWorld(g_currentMission.player.currentTool.cutNode, 1, 0, 0);
                        local yx, yy, yz = localDirectionToWorld(g_currentMission.player.currentTool.cutNode, 0, 1, 0);
                        ChainsawUtil.cutSplitShape(shape, x, y, z, nx, ny, nz, yx, yy, yz, 1, 1);
                    end
                
                end
                
                -- spruce piantato che sta crescendo, però se è meno di 2.2 probabilmente è un ceppo.
                if volume < 3 and splitType.splitType == 1 and firewood.cutHz and maxSize > 2.2 and massa == 1 and bdyPezzi == "Static" then
                    firewood.pineGrowing = true;
                else
                    firewood.pineGrowing = false;
                end
            
            end
            if self.txtPezzi ~= "" then
                --Utils.renderTextAtWorldPosition(x, y, z, self.txtPezzi, getCorrectTextSize(0.02), 0);
                --Utils.renderTextAtWorldPosition(x+1, y, z, self.txtPezzi, getCorrectTextSize(0.02), 0);
                firewood.renderTxtWP(x, y, z, self.txtPezzi, getCorrectTextSize(0.020), 0);
                
                -- debug
                renderText(0.01, 0.01, self.fontSize, ("%.3f"):format(maxZ) .. "  <-->  " .. ("%.3f"):format(minZ) .. "  x:" .. ("%.3f"):format(x) .. "  y:" .. ("%.3f"):format(y) .. "  z:" .. ("%.3f"):format(z) .. "  ");
            
            end
        else
            self.txtPezzi = "";
        end
        ----------------------
        
        -- tagli orizzontali, normalmente abbattimento del tronco
        if self.cutHz and self.cutSt and shape ~= 0 then
            -- quando finisce di tagliare dovrebbe calcolare l'addimpulse per farlo cadere sicuro...
            local impulsePerTon = 4;
            local objectMass = getMass(shape);
            local impulse = math.sqrt(impulsePerTon * objectMass);
            local partX, partZ = -math.sin(maxY), -math.cos(maxY);
            local partSum = math.abs(partX) + math.abs(partZ);
            local impulseX = impulse * partX / partSum;
            local impulseY = impulse * 0.1;
            local impulseZ = impulse * partZ / partSum;
            addImpulse(shape, impulseX, impulseY, impulseZ, x, y, z, false);
            print("firewood debug: " .. tostring(self.cutHz) .. "  " .. tostring(self.cutSt));
        end
        
        -- delimb...
        if self.cutDl and not (self.cutOn) then
            if math.random(10) > 7 then
                self.cutCNT = self.cutCNT + 1;
            end
        end
        
        -- cut
        if self.cutOn and self.cutDl then
            if math.random(10) > 5 then
                self.cutCNT = self.cutCNT + 1;
            end
        end
        
        -- azzero la misura dopo la fine di un taglio e reimposto la posizione
        if self.cutSt then
            self.misura = 0;
            self.metro = true;
            aX1, aY1, aZ1 = getWorldTranslation(p);
        end
        
        if self.cutCNT >= 1000 then
            local eccedenza = self.cutCNT - 1000;
            self.numCNT = self.numCNT + 1;
            self.cutCNT = eccedenza;
            eccedenza = 0;
        end
        
        --if Input.isKeyPressed(Input.KEY_r) and self.numCNT >= 2 then
        if InputBinding.hasEvent(InputBinding.FW_SELLFW) and self.numCNT >= 2 then
            
            local quanteff = (1000 * self.numCNT - 1) + self.cutCNT;
            local addmoney = math.floor((pagLegna * quanteff) / 1000);
            local addchip = math.floor(quanteff / g_currentMission.missionInfo.difficulty);
            self.cutCNT = 0;
            self.numCNT = 1;
            -- debug
            print("firewood debug: QTA " .. tostring(quanteff) .. "  money " .. tostring(addmoney) .. "  chip " .. tostring(addchip));
            
            quanteff = 0; addmoney = 0; addchip = 0;

            self:createWoodPack()

        end    
    end
    
    if self.woodOverlayTime > 0 then
        self.woodOverlayTime = self.woodOverlayTime - dt;
    end
    
    --[[ questo forse serve in futuro...
    if shape ~= nil and shape ~= 0 then
    local cutTooLow = false;
    if getVolume(shape) < 0.1 and getMass(shape) < 0.05 then cutTooLow = true; end;
    if cutTooLow then
    g_currentMission.player.walkingIsLocked = false;
    g_currentMission.player.currentTool.curSplitShape = nil;
    shape, minY,maxY, minZ,maxZ = 0, nil,nil, nil,nil;
    end;
    end;
    --]]
    if g_currentMission.showHelpText and self.numCNT >= 2 then
        g_currentMission:addHelpButtonText(g_i18n:getText("FW_SELLFW"), InputBinding.FW_SELLFW);
    end
end


function firewood:updateTick(dt)
end


function firewood:draw()
    local povlX = g_currentMission.weatherForecastBgOverlay.x;
    local povlY = g_currentMission.weatherForecastBgOverlay.y - 0.22;
    local wdth = pxToNormal(176, 'x');
    local hgth = pxToNormal(176, 'y');
    
    if g_currentMission.renderTime and g_currentMission.player.currentTool ~= nil then
        renderOverlay(self.bgOverlay, povlX, povlY, (wdth * 2) + 0.010, hgth + 0.010);
        renderOverlay(self.woodOverlay, povlX, povlY, wdth, hgth);
        setTextColor(0.95, 0.95, 0.95, 1);
        renderText(povlX + 0.10, povlY + 0.140, firewood.fontSize, firewood.econStringA .. " ");
        
        if firewood.txtPezzi ~= "" then
            setTextColor(0.95, 0.95, 0.95, 1);
            renderText(povlX + 0.07, povlY + 0.158, firewood.fontSize, firewood.txtPezzi);
            firewood.resetSetRendOpt();
        end
        
        if firewood.segaon then
            renderText(povlX + 0.008, povlY + 0.01, firewood.fontSize, firewood.statString);
            local packBar = Utils.clamp((firewood.cutCNT / 1000), 0, 1);
            if packBar > 1 then packBar = 1; end;
            firewood.resetSetRendOpt();
            
            if packBar <= 0.70 then setOverlayColor(self.graphOverlay, 0, 1, 0.5, 0.5); end;
            if packBar >= 0.75 then setOverlayColor(self.graphOverlay, 0.55, 0.55, 0, 0.5); end;
            if packBar >= 0.85 then setOverlayColor(self.graphOverlay, 1, 0.55, 0, 0.5); end;
            if packBar >= 0.95 then setOverlayColor(self.graphOverlay, 1, 0, 0, 0.5); end;
            renderOverlay(self.graphOverlay, povlX + 0.09, povlY + 0.034, 0.009, packBar / 10);
            renderText(povlX + 0.09, povlY + 0.02, self.fontSize, "pallet # " .. tostring(self.numCNT));
            
            
            -- debug
            -- renderText(0.01, 0.01, self.fontSize, ("%.3f"):format(aX1).."  "..("%.3f"):format(aY1).."  "..("%.3f"):format(aZ1).." sx:"..("%.3f"):format(sx).."  sy:"..("%.3f"):format(sy).."  ");
            -- renderText(0.01, 0.01, 0.014, "On:"..tostring(self.cutOn).." Hz:"..tostring(self.cutHz).."  Dl:"..tostring(self.cutDl).."  St:"..tostring(self.cutSt).."  segaon:"..tostring(self.segaon).."  "..self.txtPezzi.."  "..self.secTimer);
            if self.txtPezzi ~= "" then
                local x, y, z = getWorldTranslation(g_currentMission.player.currentTool.cutNode);
                local nx, ny, nz = localDirectionToWorld(g_currentMission.player.currentTool.cutNode, 1, 0, 0);
                local yx, yy, yz = localDirectionToWorld(g_currentMission.player.currentTool.cutNode, 0, 1, 0);
                drawDebugLine(nx, ny, nx, 1, 0, 0, yx, yy, yz, 1, 0, 0);
            end
        
        end
        
        if self.woodOverlayTime > 0 then
            renderText(povlX + 0.09, povlY + 0.11, firewood.fontSize, firewood.econStringB);
        end
        if self.metro then
            setTextColor(0, 0, 0, 1);
            renderText(0.55, 0.12, 0.022, " m. " .. ("%.2f"):format(firewood.misura));
            setTextColor(1, 0, 0, 1);
            renderText(0.55, 0.12, 0.022, " _ _ _ _ _ _ _ _ _ _ _ ");
            firewood.resetSetRendOpt();
            setOverlayColor(self.graphOverlay, 1, 0.93, 0, 0.4);
            renderOverlay(self.graphOverlay, 0.548, 0.115, 0.075, 0.0325);
        end
        firewood.resetSetRendOpt();
    end

--renderText(0.5, 0.05, self.fontSize, tostring(g_currentMission.time));
end

-----------------------------------------------------------------------------
-- supporto multiplayer
-----------------------------------------------------------------------------
firewoodShapeEvent = {};
firewoodShapeEvent_mt = Class(firewoodShapeEvent, Event);
InitEventClass(firewoodShapeEvent, "firewoodShapeEvent");
function firewoodShapeEvent:emptyNew()
    local self = Event:new(firewoodShapeEvent_mt);
    self.className = "firewoodShapeEvent";
    return self;
end

function firewoodShapeEvent:new(shape)
    local self = firewoodShapeEvent:emptyNew()
    self.shape = shape;
    return self;
end

function firewoodShapeEvent:writeStream(streamId, connection)
    -- print(tostring(g_currentMission.time).. "ms - firewoodShapeEvent:writeStream(streamId, connection)");
    writeSplitShapeIdToStream(streamId, self.shape);
end

function firewoodShapeEvent:readStream(streamId, connection)
    -- print(tostring(g_currentMission.time).. "ms - firewoodShapeEvent:readStream(streamId, connection)");
    self.shape = readSplitShapeIdFromStream(streamId);
    self:run(connection);
end

function firewoodShapeEvent:run(connection)
    if self.shape ~= nil and self.shape ~= 0 then
        g_currentMission.firewoodBase:deleteSlice(self.shape);
    end
end