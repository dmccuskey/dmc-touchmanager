# Changelog

## 2.1.0 (2026-09-30)

### Changed

- A removed object is forgotten: when Solar2D sends it the `finalize` event, at the end of the frame it's removed in, the Touch Manager drops it and releases its focused touches. It stayed registered, and its touches still went to its handlers.
- `unregister()` of an object's last handler releases the object's focused touches; they stayed focused unless the handler called `unsetFocus()`.
- The made-up event `unregister()` sends for each focused touch is `cancelled`, not `ended`, with the touch's last `x`, `y`, `xStart` and `yStart`; they were all `0`.
- `unregister()` of a handler that isn't registered does nothing. It raised `handlers to not match`, after adding the Touch Manager's listener to the object.
- An object's handlers are called in the order they were registered; the order wasn't set. A handler that unregisters another during an event no longer stops it getting that event.
- A focused touch counts as handled, whatever the handlers return, and so does a touch focused in its `began`. When the handlers returned `false`, Solar2D sent the event on to `Runtime`, and the Touch Manager sent it to the object a second time.
- `unregisterGestureMgr()` clears the object's gesture manager, so one can be registered again; the object stays registered while it has a gesture manager, even with no handlers (unregistering its last handler cut the gesture manager off). Registering the same gesture manager twice does nothing. `_getRegisteredManager()` works; it called a function that doesn't exist.
- Rebuilt with dmc-corona-boot 1.6.0.

### Added

- `TouchMgr.VERSION`.
- Unit tests, and `tests/run_unit.sh` to run them with plain Lua 5.1.

### Removed

- The unused configuration block and its copy of `extend()`, which leaked the global `_extend`.
- The unused `shouldDelayBeganTouches` and `shouldDelayEndedTouches` checks for gesture managers: no gesture manager sets them, and the delaying was never written.
