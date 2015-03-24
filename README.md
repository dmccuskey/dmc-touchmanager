# dmc-touchmanager

Brings true multi-touch to the Corona SDK

This module was created because to patch the current multitouch capability in Corona SDK so it functions as expected.

Examples can be found in the directory `examples`


**Simple Function Handler Example**

```lua
local TouchMgr = require 'dmc_touchmanager'

-- setup our function-type event call
--
local handler = function( event )
	local target = event.target

	if event.phase == 'began' then

		-- set focus if the object (target) wants to
		-- always receive this event (blocking all others)
		TouchMgr:setFocus( event.target, event.id )

		return true
	end

	if not event.isFocused then return end

	if event.phase == 'moved' then 
		-- handle 'moved' event

	elseif event.phase=='cancelled' or event.phase=='ended' then
		-- handle 'ended'/'cancelled' event

		-- be sure to unset focus
		TouchMgr:unsetFocus( event.target, event.id )

	end

	return true
end

local o = display.newRect( 350, 700, 300, 300 )
o:setFillColor( 1, 1, 1 )

TouchMgr:register( o, handler )
```

