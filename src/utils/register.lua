--
-- firewood utilities, register special bale for wood.
--
-- fcelsa (Team FSI Modding)
--
-- 22/04/2018
register = {};
register.dir = g_currentModDirectory;

BaleUtil.registerBaleType(register.dir .. "bales/firewoodpack.i3d", "straw", 1.22, nil, nil, 1.01, true);

print("firewood: register special bale for wood pack")

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

addModEventListener(register);
