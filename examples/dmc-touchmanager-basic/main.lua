--====================================================================--
-- Touch Manager Basic
--
-- Shows simple use of the Touch Manager
--
-- Sample code is MIT licensed, the same license which covers Lua itself
-- http://en.wikipedia.org/wiki/MIT_License
-- Copyright (C) 2012-2015 David McCuskey. All Rights Reserved.
--====================================================================--



print( '\n\n##############################################\n\n' )



--====================================================================--
--== Imports


local TouchMgr = require 'dmc_corona.dmc_touchmanager'



--====================================================================--
--== Setup, Constants


local W, H = display.contentWidth, display.contentHeight
local H_CENTER, V_CENTER = W*0.5, H*0.5

display.setStatusBar( display.HiddenStatusBar )



--====================================================================--
--== Support Functions


--- create Display Object used to represent a screen touch
--
-- @table color (array) with R,G,B values
-- @return instance of display object
--
local function createTouchPoint( color )
	local o = display.newCircle( 0, 0, 20 )
	o:setFillColor( unpack( color ) )
	return o
end


--- create a regular Display Object for touch area
-- add some properties used for touch management
--
-- @table fColor (array) with R,G,B values, fill color
-- @return instance of display object
--
local function createDisplayObject( fColor )

	local o = display.newRect( 0, 0, 150, 150 )
	o:setFillColor( unpack( fColor ) )
	o.alpha = 0.5

	--== setup vars ON display object to track touches

	-- active number of touches for our shape
	o._touch_num = 0

	-- table holding visual touch points, hashed by touch-event id
	o._touch_points = {}

	return o
end


--== Helper functions, showing activity

local function updateDisplayObject( o, sColor, sWidth )
	o:setStrokeColor( unpack( sColor ) )
	o.strokeWidth = sWidth
end

local function highlightDisplayObject( o )
	updateDisplayObject( o, { 0.7, 0.7, 0.7 }, 10 )
end

local function unhighlightDisplayObject( o )
	updateDisplayObject( o, { 0, 0, 0 }, 0 )
end



--======================================================--
-- Setup Object-type Handler

local function setup_object_example()

	--== setup our display object

	local color = { 1, 1, 1 }
	local o = createDisplayObject( color )
	o.x, o.y = H_CENTER, V_CENTER-115


	--== setup our object-type event call

	function o:touch( event )
		-- print( "o:touch", event.phase, event.id )
		local tp -- visual touch point

		if event.phase == 'began' then

			highlightDisplayObject( o )

			tp = createTouchPoint( color )
			tp.x, tp.y = event.x, event.y
			self._touch_points[ event.id ] = tp
			self._touch_num = self._touch_num + 1

			TouchMgr.setFocus( self, event.id )

			return true
		end

		if not event.isFocused then return end

		if event.phase == 'moved' then

			tp = self._touch_points[ event.id ]
			if tp then
				tp.x, tp.y = event.x, event.y
			end


		elseif ( event.phase=='ended' or event.phase=='cancelled' ) then

			TouchMgr.unsetFocus( self, event.id )

			tp = self._touch_points[ event.id ]
			assert( tp, 'tp not found', event.id )
			if tp then
				self._touch_num = self._touch_num - 1
				self._touch_points[ event.id ] = nil
				tp:removeSelf()
			end

			if self._touch_num == 0 then
				unhighlightDisplayObject( o )
			end

		end

		return true
	end


	-- return object reference back for Touch Manager initialization
	return o
end



--======================================================--
-- Setup Function-type Handler

local function setup_function_example()

	--== setup display object

	local color = { 1, 0, 0 }
	local o = createDisplayObject( color )
	o.x, o.y = H_CENTER, V_CENTER+115


	--== setup our function-type event call

	local handler = function( event )
		-- print( "handler", event, event.phase )
		local target = event.target -- our display object, 'o'

		if event.phase=='began' then

			highlightDisplayObject( target )

			tp = createTouchPoint( color )
			tp.x, tp.y = event.x, event.y
			target._touch_points[ event.id ] = tp
			target._touch_num = target._touch_num + 1

			TouchMgr.setFocus( target, event.id )

			return true
		end

		if not event.isFocused then return end

		if event.phase=='moved' then

			tp = target._touch_points[ event.id ]
			if tp then
				tp.x, tp.y = event.x, event.y
			end


			elseif ( event.phase=='ended' or event.phase=='cancelled' ) then

			TouchMgr.unsetFocus( target, event.id )

			tp = target._touch_points[ event.id ]
			assert( tp, 'tp not found', event.id )
			if tp then
				target._touch_num = target._touch_num - 1
				target._touch_points[ event.id ] = nil
				tp:removeSelf()
			end

			if target._touch_num == 0 then
				unhighlightDisplayObject( target )
			end

		end

		return true
	end

	-- return references back for Touch Manager initialization
	return o, handler
end



--====================================================================--
--== Main
--====================================================================--


local function main()

	local o, h

	-- register the object as OO with the Touch Manager

	o = setup_object_example()
	TouchMgr.register( o )

	-- register the object/handler with the Touch Manager

	o, h = setup_function_example()
	TouchMgr.register( o, h )

	-- timer.performWithDelay( 20000, function()
	-- 	TouchMgr.unregister( o, h )
	-- end)

end


-- start the action !

main()


