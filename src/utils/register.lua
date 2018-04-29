--
-- firewood utilities, register special bale for wood, register fillType firewood
--
-- fcelsa (Team FSI Modding)
--
-- 22/04/2018
register = {}
register.dir = g_currentModDirectory

--local hudOverlayFilename = g_currentModDirectory .. "";
--local hudOverlayFilenameSmall = g_currentModDirectory .. "";
local hudOverlayFilename = "dataS2/menu/hud/fillTypes/hud_fill_woodChips.png"
local hudOverlayFilenameSmall = "dataS2/menu/hud/fillTypes/hud_fill_woodChips_sml.png"

FillUtil.registerFillType(
    "firewood",
    g_i18n:getText("fillType_firewood"),
    FillUtil.FILLTYPE_CATEGORY_BULK,
    0.360,
    false,
    hudOverlayFilename,
    hudOverlayFilenameSmall,
    1000 * 0.000001,
    math.rad(0)
)

BaleUtil.registerBaleType(register.dir .. "bales/firewoodpack.i3d", "firewood", 1.22, nil, nil, 1.01, true)

print("firewood: register fillType firewood, register special bale for wood pack")

function register:loadMap(name)
end

function register:deleteMap()
end

function register:keyEvent(unicode, sym, modifier, isDown)
end

function register:mouseEvent(posX, posY, isDown, isUp, button)
end

function register:update(dt)
end

function register:draw()
end

addModEventListener(register)
