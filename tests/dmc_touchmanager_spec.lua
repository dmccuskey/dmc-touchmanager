--====================================================================--
-- tests/dmc_touchmanager_spec.lua
--
-- Unit tests for dmc-touchmanager, using Luna Test.
-- Run with tests/run_unit.sh
--
-- Solar2D's Runtime and display objects are stand-ins here; deliver()
-- sends a touch the way Solar2D does: to each object under it, top
-- first, until a listener returns true, then to Runtime
--====================================================================--


module(..., package.seeall)



--====================================================================--
--== Setup


local MODULE = 'dmc_corona.dmc_touchmanager'

-- stand-ins for the Solar2D globals the module uses
package.preload.json = function() return require 'dkjson' end

_G.system = {
	ResourceDirectory=newproxy(),
	pathForFile=function( name ) return './'..name end,
	activate=function( name ) system.activated = name end,
}

-- addListeners()
-- gives o Solar2D's addEventListener() and removeEventListener()
--
local function addListeners( o )
	o.listeners = {}
	function o:addEventListener( name, f )
		self.listeners[ name ] = self.listeners[ name ] or {}
		table.insert( self.listeners[ name ], f )
	end
	function o:removeEventListener( name, f )
		for i, g in ipairs( self.listeners[ name ] or {} ) do
			if g == f then table.remove( self.listeners[ name ], i ) return end
		end
	end
	function o:countListeners( name )
		return #( self.listeners[ name ] or {} )
	end
	-- the listeners' answer: true if any returned true
	function o:dispatchEvent( event )
		local handled = false
		for _, f in ipairs( self.listeners[ event.name ] or {} ) do
			if f( event ) then handled = true end
		end
		return handled
	end
	return o
end

local function newObject( name )
	return addListeners{ name=name }
end

-- removeObject()
-- Solar2D's removeSelf(): the object gets a 'finalize' event
--
local function removeObject( o )
	o:dispatchEvent{ name='finalize', target=o }
end

-- deliver()
-- a touch event, to each object in objs, then to Runtime
-- @return the object which handled it, 'Runtime', or nil
--
local function deliver( objs, event )
	event.name = 'touch'
	for _, o in ipairs( objs ) do
		event.target = o
		if o:dispatchEvent( event ) then return o end
	end
	event.target = nil
	if Runtime:dispatchEvent( event ) then return 'Runtime' end
	return nil
end

-- touchEvent()
-- a touch with id 'A', at x, y
--
local function touchEvent( phase, x, y, id )
	return { phase=phase, id=id or 'A', x=x or 0, y=y or 0, xStart=1, yStart=2 }
end

-- load()
-- a fresh copy of the module, with a fresh Runtime
--
local function load()
	_G.Runtime = newObject( 'Runtime' )
	package.loaded[ MODULE ] = nil
	package.loaded[ 'dmc_corona_boot' ] = nil
	_G.__dmc_corona = nil
	return require( MODULE )
end

-- recorder()
-- a handler function which records each event's phase, target and
-- isFocused in log, and returns ret
--
local function recorder( log, label, ret )
	return function( event )
		table.insert( log, { label=label, phase=event.phase,
			target=event.target, isFocused=event.isFocused,
			x=event.x, y=event.y, xStart=event.xStart, yStart=event.yStart } )
		return ret
	end
end

-- focuser()
-- the usual handler: focus in 'began', release in 'ended'
--
local function focuser( TouchMgr, log )
	return function( event )
		table.insert( log, { phase=event.phase, target=event.target,
			isFocused=event.isFocused, x=event.x, y=event.y } )
		if event.phase == 'began' then
			TouchMgr.setFocus( event.target, event.id )
		elseif event.phase == 'ended' then
			TouchMgr.unsetFocus( event.target, event.id )
		end
		return true
	end
end



--====================================================================--
--== Tests


function test_module()
	local TouchMgr = load()
	assert_equal( '2.1.0', TouchMgr.VERSION )
	assert_equal( 'multitouch', system.activated )
	assert_equal( 1, Runtime:countListeners( 'touch' ) )
end

function test_no_globals()
	-- master's leaked by an earlier test's load
	rawset( _G, '_extend', nil )
	local before = {}
	for k in pairs( _G ) do before[ k ] = true end
	local TouchMgr = load()
	local o = newObject( 'o' )
	TouchMgr.register( o, function() return true end )
	deliver( { o }, touchEvent( 'began' ) )
	for k in pairs( _G ) do
		if not before[ k ] and k ~= '__dmc_corona' then
			fail( 'new global: '..tostring( k ) )
		end
	end
end

function test_function_and_table_handlers()
	local TouchMgr = load()
	local log = {}
	local o = newObject( 'o' )
	TouchMgr.register( o, recorder( log, 'f' ) )
	function o:touch( event )
		table.insert( log, { label='self', target=event.target } )
	end
	TouchMgr.register( o )
	assert_nil( deliver( { o }, touchEvent( 'began' ) ) )
	assert_equal( 2, #log )
	assert_equal( 'f', log[1].label )
	assert_equal( o, log[1].target )
	assert_false( log[1].isFocused )
	assert_equal( 'self', log[2].label )
end

function test_handlers_in_order_and_once()
	local TouchMgr = load()
	local log = {}
	local o = newObject( 'o' )
	local labels = { 'c', 'a', 'd', 'b', 'e' }
	local handlers = {}
	for i, label in ipairs( labels ) do
		handlers[ i ] = recorder( log, label )
		TouchMgr.register( o, handlers[ i ] )
	end
	TouchMgr.register( o, handlers[ 1 ] )
	assert_equal( 1, o:countListeners( 'touch' ) )
	deliver( { o }, touchEvent( 'began' ) )
	assert_equal( #labels, #log )
	for i, label in ipairs( labels ) do
		assert_equal( label, log[ i ].label )
	end
end

function test_handled_when_any_returns_true()
	local TouchMgr = load()
	local o = newObject( 'o' )
	TouchMgr.register( o, function() return false end )
	TouchMgr.register( o, function() return true end )
	assert_equal( o, deliver( { o }, touchEvent( 'began' ) ) )
end

function test_unregister_during_dispatch()
	local TouchMgr = load()
	local log = {}
	local o = newObject( 'o' )
	local third = recorder( log, 'third' )
	TouchMgr.register( o, function( event )
		table.insert( log, { label='first' } )
		if event.phase == 'began' then TouchMgr.unregister( o, third ) end
	end )
	TouchMgr.register( o, recorder( log, 'second' ) )
	TouchMgr.register( o, third )
	-- this event goes to all three
	deliver( { o }, touchEvent( 'began' ) )
	assert_equal( 3, #log )
	assert_equal( 'third', log[3].label )
	-- the next one doesn't go to the third
	deliver( { o }, touchEvent( 'moved' ) )
	assert_equal( 5, #log )
	assert_equal( 'second', log[5].label )
end

function test_focused_touch_stays_with_its_object()
	local TouchMgr = load()
	local log, other = {}, {}
	local a, b = newObject( 'a' ), newObject( 'b' )
	TouchMgr.register( a, focuser( TouchMgr, log ) )
	TouchMgr.register( b, recorder( other, 'b', true ) )
	assert_equal( a, deliver( { a }, touchEvent( 'began' ) ) )
	-- over b: goes to a's handlers, handled at b
	assert_equal( b, deliver( { b }, touchEvent( 'moved', 5, 6 ) ) )
	-- over nothing: Runtime sends it to a
	assert_equal( 'Runtime', deliver( {}, touchEvent( 'moved', 7, 8 ) ) )
	assert_equal( 'Runtime', deliver( {}, touchEvent( 'ended', 9, 9 ) ) )
	assert_equal( 0, #other )
	assert_equal( 4, #log )
	for i = 2, 4 do
		assert_equal( a, log[ i ].target )
		assert_true( log[ i ].isFocused )
	end
	assert_nil( TouchMgr._FOCUS.A )
end

function test_focused_touch_dispatched_once()
	local TouchMgr = load()
	local log = {}
	local o = newObject( 'o' )
	TouchMgr.register( o, function( event )
		table.insert( log, event.phase )
		if event.phase == 'began' then TouchMgr.setFocus( o, event.id ) end
		return false
	end )
	deliver( { o }, touchEvent( 'began' ) )
	-- the handlers return false, but a focused touch counts as handled:
	-- it doesn't go on to Runtime and back to o
	assert_equal( o, deliver( { o }, touchEvent( 'moved' ) ) )
	assert_equal( 2, #log )
end

function test_runtime_ignores_unfocused_touches()
	local TouchMgr = load()
	local log = {}
	local o = newObject( 'o' )
	TouchMgr.register( o, recorder( log, 'o' ) )
	assert_nil( deliver( {}, touchEvent( 'began' ) ) )
	-- the touch passed over o: Runtime doesn't send it there again
	assert_nil( deliver( { o }, touchEvent( 'moved' ) ) )
	assert_equal( 1, #log )
end

function test_unregister_unknown_handler()
	local TouchMgr = load()
	local o = newObject( 'o' )
	TouchMgr.unregister( o, function() end )
	assert_equal( 0, o:countListeners( 'touch' ) )
	assert_nil( TouchMgr._OBJECT[ o ] )
	TouchMgr.register( o, function() end )
	TouchMgr.unregister( o, function() end )
	assert_not_nil( TouchMgr._OBJECT[ o ] )
end

function test_unregister_last_handler_releases_focus()
	local TouchMgr = load()
	local log = {}
	local o = newObject( 'o' )
	local seen = {}
	-- focuses, but never releases
	local handler = function( event )
		table.insert( seen, event )
		if event.phase == 'began' then TouchMgr.setFocus( o, event.id ) end
		return true
	end
	TouchMgr.register( o, handler )
	deliver( { o }, touchEvent( 'began', 3, 4 ) )
	deliver( {}, touchEvent( 'moved', 30, 40 ) )
	TouchMgr.unregister( o, handler )
	local evt = seen[ #seen ]
	assert_equal( 'cancelled', evt.phase )
	assert_equal( 'A', evt.id )
	assert_equal( o, evt.target )
	assert_true( evt.isFocused )
	assert_equal( 30, evt.x )
	assert_equal( 40, evt.y )
	assert_equal( 1, evt.xStart )
	assert_equal( 2, evt.yStart )
	assert_nil( TouchMgr._FOCUS.A )
	assert_nil( TouchMgr._POSITION.A )
	assert_nil( TouchMgr._OBJECT[ o ] )
	assert_equal( 0, o:countListeners( 'touch' ) )
	assert_equal( 0, o:countListeners( 'finalize' ) )
	-- the touch is off: later events go nowhere
	assert_nil( deliver( {}, touchEvent( 'ended' ) ) )
	assert_equal( 3, #seen )
end

function test_unregister_one_of_two_keeps_focus()
	local TouchMgr = load()
	local log = {}
	local o = newObject( 'o' )
	local first = focuser( TouchMgr, log )
	local cancelled = {}
	local second = function( event )
		if event.phase == 'cancelled' then table.insert( cancelled, event ) end
	end
	TouchMgr.register( o, first )
	TouchMgr.register( o, second )
	deliver( { o }, touchEvent( 'began' ) )
	TouchMgr.unregister( o, second )
	assert_equal( 1, #cancelled )
	assert_equal( o, TouchMgr._FOCUS.A )
	deliver( {}, touchEvent( 'moved' ) )
	assert_equal( 2, #log )
end

function test_unregister_with_no_focus()
	local TouchMgr = load()
	local called = 0
	local o = newObject( 'o' )
	local handler = function() called = called + 1 end
	TouchMgr.register( o, handler )
	TouchMgr.unregister( o, handler )
	assert_equal( 0, called )
	assert_nil( TouchMgr._OBJECT[ o ] )
end

function test_removed_object_is_forgotten()
	local TouchMgr = load()
	local log = {}
	local o = newObject( 'o' )
	TouchMgr.register( o, focuser( TouchMgr, log ) )
	deliver( { o }, touchEvent( 'began' ) )
	removeObject( o )
	assert_nil( TouchMgr._OBJECT[ o ] )
	assert_nil( TouchMgr._FOCUS.A )
	assert_nil( deliver( {}, touchEvent( 'moved' ) ) )
	assert_equal( 1, #log )
end

-- newGestureMgr()
-- a stand-in for dmc-gestures' gesture manager
--
local function newGestureMgr( view, log )
	return {
		view=view,
		touch=function( self, event )
			table.insert( log, { label='g_mgr', phase=event.phase } )
		end
	}
end

function test_gesture_manager_first()
	local TouchMgr = load()
	local log = {}
	local o = newObject( 'o' )
	local g_mgr = newGestureMgr( o, log )
	TouchMgr.register( o, recorder( log, 'h' ) )
	TouchMgr.registerGestureMgr( g_mgr )
	assert_equal( TouchMgr, g_mgr.touch_manager )
	assert_equal( g_mgr, TouchMgr._getRegisteredManager( o ) )
	assert_equal( o, deliver( { o }, touchEvent( 'began' ) ) )
	assert_equal( 'g_mgr', log[1].label )
	assert_equal( 'h', log[2].label )
end

function test_gesture_manager_outlives_handlers()
	local TouchMgr = load()
	local log = {}
	local o = newObject( 'o' )
	local handler = recorder( log, 'h' )
	local g_mgr = newGestureMgr( o, log )
	TouchMgr.register( o, handler )
	TouchMgr.registerGestureMgr( g_mgr )
	TouchMgr.unregister( o, handler )
	-- the gesture manager still gets the object's touches
	deliver( { o }, touchEvent( 'began' ) )
	assert_equal( 1, #log )
	assert_equal( 'g_mgr', log[1].label )
	TouchMgr.unregisterGestureMgr( g_mgr )
	assert_nil( TouchMgr._OBJECT[ o ] )
	assert_nil( TouchMgr._getRegisteredManager( o ) )
	assert_equal( 0, o:countListeners( 'touch' ) )
end

function test_gesture_manager_register_again()
	local TouchMgr = load()
	local log = {}
	local o = newObject( 'o' )
	TouchMgr.register( o, recorder( log, 'h' ) )
	local g1, g2 = newGestureMgr( o, log ), newGestureMgr( o, log )
	TouchMgr.registerGestureMgr( g1 )
	TouchMgr.registerGestureMgr( g1 )
	assert_false( pcall( TouchMgr.registerGestureMgr, g2 ) )
	TouchMgr.unregisterGestureMgr( g1 )
	assert_nil( TouchMgr._getRegisteredManager( o ) )
	-- the object keeps its handler, and takes a new manager
	assert_not_nil( TouchMgr._OBJECT[ o ] )
	TouchMgr.registerGestureMgr( g2 )
	assert_equal( g2, TouchMgr._getRegisteredManager( o ) )
	-- unregistering a manager which isn't the object's does nothing
	TouchMgr.unregisterGestureMgr( g1 )
	assert_equal( g2, TouchMgr._getRegisteredManager( o ) )
end
