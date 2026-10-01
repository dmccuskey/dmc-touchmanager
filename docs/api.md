# API Reference

Everything dmc-touchmanager provides, for version 2.1.0. The [Quick Start](../README.md#quick-start) shows it in use.

## Quick Reference

| Call | Does | Instead of |
|---|---|---|
| [`TouchMgr.register( obj [, handler] )`](#touchmgrregister-obj--handler-) | sends `obj`'s touches to `handler` | `obj:addEventListener( 'touch', handler )` |
| [`TouchMgr.unregister( obj [, handler] )`](#touchmgrunregister-obj--handler-) | stops sending them | `obj:removeEventListener( 'touch', handler )` |
| [`TouchMgr.setFocus( obj, event.id )`](#touchmgrsetfocus-obj-id-) | gives the touch to `obj`, wherever it moves | `stage:setFocus( obj, event.id )` |
| [`TouchMgr.unsetFocus( obj, event.id )`](#touchmgrunsetfocus-obj-id-) | releases that one touch | `stage:setFocus( nil, event.id )` |
| [`event.isFocused`](#the-touch-event) | `true` when the touch is focused on the handler's object | |
| `TouchMgr.VERSION` | the version, `'2.1.0'` | |

Every call uses a dot (`.`), not a colon: `TouchMgr:register( obj )` passes `TouchMgr` as the object and fails.

## The Module

```lua
local TouchMgr = require 'dmc_corona.dmc_touchmanager'
```

Loading it calls `system.activate( 'multitouch' )`, so the app doesn't need to, and adds one `touch` listener to `Runtime`. There is one Touch Manager per app; requiring it again returns the same table. `TouchMgr.VERSION` is its version.

## Why It Exists

Solar2D can focus a touch on an object with `stage:setFocus( object, event.id )`, so that the object gets the touch's events even after it moves off it. But each object holds focus for one touch id at a time: focusing a second touch on the same object replaces the first, and the first touch's events go back to whatever is under them. A pinch or a rotate needs two touches on one object.

dmc-touchmanager keeps its own list of focused touches, any number per object, and doesn't use `stage:setFocus()`.

## Registering Objects

### TouchMgr.register( obj [, handler] )

Sends the touch events of display object `obj` to `handler`, through the Touch Manager.

- A function: it's called as `handler( event )`.
- A table: its `touch` method is called, `handler:touch( event )`.
- Left out: `obj` itself is the handler, so `obj:touch( event )` is called.

An object can have several handlers; each gets every event, in the order they were registered. Registering the same handler twice has no extra effect. The event counts as handled (it stops going to objects below) when any handler returns `true`.

```lua
-- a function listener
local function onTouch( event )
	print( event.phase, event.target.name )
	return true
end
TouchMgr.register( button, onTouch )

-- a table listener: the object's own touch() method
function button:touch( event )
	...
end
TouchMgr.register( button )
```

Don't also add the handler with `obj:addEventListener( 'touch', ... )`: it would get each event twice.

### TouchMgr.unregister( obj [, handler] )

Stops sending `obj`'s touch events to `handler` (or to `obj` itself, when `handler` is left out). A handler that isn't registered for `obj` is ignored. A handler can unregister itself, or another, while it handles an event: the handlers already called for that event still get it.

If the object holds focused touches, the handler gets one last made-up `cancelled` event for each, with `isFocused = true` and the touch's last `x`, `y`, `xStart` and `yStart`, so it can clean up. When the object has no handlers left (and no gesture manager), the Touch Manager removes its own listener from it and releases its focused touches.

An object removed with `removeSelf()` needs no `unregister()`: the Touch Manager forgets it, and releases its touches, when Solar2D sends it the `finalize` event, at the end of that frame. Its handlers aren't called.

## Focus

### TouchMgr.setFocus( obj, id )

Gives the touch with id `id` (`event.id`) to `obj`. From then on, until `unsetFocus()` (or `obj` is unregistered or removed), every event of that touch goes to `obj`'s handlers, with `event.target` set to `obj` and `event.isFocused` set to `true`, wherever the touch is: over `obj`, over another registered object, or over nothing. Call it in the `began` phase.

`obj` must be registered. Any number of touches can be focused on one object; a touch can be focused on one object.

### TouchMgr.unsetFocus( obj, id )

Releases the touch with id `id`. Call it in the `ended` and `cancelled` phases, for every touch you focused; a touch that is never released stays in the focus list. `obj` isn't checked: the touch is released whatever object holds it.

## The Touch Event

Handlers get Solar2D's own [touch event](https://docs.coronalabs.com/api/event/touch/index.html), with these changes:

| Field | Value |
|---|---|
| `isFocused` | `true` if the touch is focused, with `setFocus()`, on the object the handler is registered for; `false` otherwise |
| `target` | for a focused touch, the object that holds it, even when the touch is over another object or none |

The usual handler focuses the touch in `began`, then ignores events whose `isFocused` is `false`: they belong to touches that began somewhere else and are passing over the object.

```lua
local function onTouch( event )
	if event.phase == 'began' then
		TouchMgr.setFocus( event.target, event.id )
		return true
	end
	if not event.isFocused then return false end

	if event.phase == 'moved' then
		-- follow the touch
	elseif event.phase == 'ended' or event.phase == 'cancelled' then
		TouchMgr.unsetFocus( event.target, event.id )
	end
	return true
end
```

There's no need for the `self.isFocus` flag that Solar2D touch handlers often keep: `event.isFocused` replaces it.

## How Touches Are Routed

`register()` adds the Touch Manager's own `touch` listener to the object, and the Touch Manager listens on `Runtime` too, which gets the touches no object handled. For each event:

1. If the touch is focused on an object, the event goes to that object's handlers, with `target` set to it and `isFocused = true`, whichever registered object (or `Runtime`) it arrived at. It counts as handled, whatever the handlers return, so it goes no further.
2. Otherwise it goes to the handlers of the registered object it arrived at, with `isFocused = false`. If a handler focuses it (in `began`), it counts as handled. At `Runtime` there is no such object, and the event is left alone.

So a focused touch that moves over another registered object stays with its own object: the other object's handlers never see it.

Other touch listeners take part in Solar2D's usual way. A focused touch that moves over an unregistered object whose listener returns `true` stops there and never reaches `Runtime`, so the focused object misses those events. Likewise a focus set with Solar2D's `stage:setFocus()` (Solar2D's `widget` library uses it) sends the touch to that object only. See [Known Issues](#known-issues).

## Gesture Managers

`TouchMgr.registerGestureMgr( g_mgr )` and `TouchMgr.unregisterGestureMgr( g_mgr )` are for [dmc-gestures](https://github.com/dmccuskey/dmc-gestures): a gesture manager gets each touch of its `g_mgr.view` (through `g_mgr:touch( event )`) before the object's handlers do, and keeps the object registered while it's there, with or without handlers. An object has one gesture manager at a time: registering another raises an error, registering the same one again does nothing. An app doesn't call them.

## Configuration

dmc-touchmanager has no settings: there is no `[DMC_TOUCHMANAGER]` section in `dmc_corona.cfg`. The file needs only the `[DMC_CORONA]` section, which tells the loader where the libraries are ([dmc-corona-boot Configuration](https://github.com/dmccuskey/dmc-corona-boot/blob/master/docs/configuration.md)).

## Known Issues

- **Focused touches can be lost** over an unregistered object whose touch listener returns `true`, or while `stage:setFocus()` is set on another object (as Solar2D's `widget` library does): the Touch Manager never sees those events. If the lost event is the `ended`, the touch stays focused. Register every object that handles touches, or have their listeners return `false` for touches they didn't begin.
