# This is the CoffeeScript API that wraps all of Cocoa.

{canon} = require 'pilot/canon'

# Handles the UI chrome
Chrome =
  init: ->
    console.log = OSX.NSLog

  # path - Optional. The String path to the file to base it on.
  createWindow: (path) ->
    c = OSX.AtomWindowController.alloc.initWithWindowNibName "AtomWindow"
    c.window
    c.window.makeKeyAndOrderFront null

  # Set the active window's dirty status.
  setDirty: (bool) ->
    Chrome.activeWindow().setDocumentEdited bool

  # Returns a boolean
  dirty: ->
    Chrome.activeWindow().isDocumentEdited()

  # Returns the active NSWindow object
  activeWindow: ->
    OSX.NSApplication.sharedApplication.keyWindow

  # Returns null or a file path.
  openPanel: ->
    panel = OSX.NSOpenPanel.openPanel
    panel.setCanChooseDirectories(true)
    if panel.runModal isnt OSX.NSFileHandlingPanelOKButton
      return null
    panel.filenames.lastObject

  # Returns null or a file path.
  savePanel: ->
    panel = OSX.NSSavePanel.savePanel
    if panel.runModal isnt OSX.NSFileHandlingPanelOKButton
      return null
    panel.filenames.lastObject

  writeToPasteboard: (text) ->
    pb = OSX.NSPasteboard.generalPasteboard
    pb.declareTypes_owner [OSX.NSStringPboardType], null
    pb.setString_forType text, OSX.NSStringPboardType

  openURL: (url) ->
    window.location = url
    Chrome.title _.last url.replace(/\/$/,'').split '/'

  # name - Command name, like "Find in file"
  # shortcut - String command name, e.g.
  #            "Command-T"
  #            "Command-Shift-F"
  #            "Ctrl-I"
  # callback - (env, args, request)
  #
  # Returns nothing.
  bindKey: (name, shortcut, callback) ->
    canon.addCommand
      name: name
      exec: callback
      bindKey:
        win: null
        mac: shortcut
        sender: 'editor'

  title: (text) ->
    WindowController.window.title = text

  toggleFullscreen: ->
    if Chrome.fullscreen?
      Chrome.leaveFullscreen()
    else
      Chrome.enterFullscreen()

  leaveFullscreen: ->
    Chrome.fullscreen = false

    OSX.NSMenu.setMenuBarVisible not OSX.NSMenu.menuBarVisible
    window = WindowController.window

  enterFullscreen: ->
    Chrome.fullscreen = true

    OSX.NSMenu.setMenuBarVisible not OSX.NSMenu.menuBarVisible
    window = WindowController.window

    fullscreenWindow = OSX.NSWindow.alloc.
      initWithContentRect_styleMask_backing_defer_screen(
        window.contentRectForFrameRect(window.frame),
        OSX.NSBorderlessWindowMask,
        OSX.NSBackingStoreBuffered,
        true,
        window.screen)

    contentView = window.contentView
    window.setContentView OSX.NSView.alloc.init

    fullscreenWindow.setHidesOnDeactivate true
    fullscreenWindow.setLevel OSX.NSFloatingWindowLevel
    fullscreenWindow.setContentView contentView
    fullscreenWindow.setTitle window.title
    fullscreenWindow.makeFirstResponder null

    fullscreenWindow.makeKeyAndOrderFront null
    frame = fullscreenWindow.frameRectForContentRect(fullscreenWindow.screen.frame)
    fullscreenWindow.setFrame_display_animate frame, true, true

# Handles the file system
File =
  read: (path) ->
    OSX.NSString.stringWithContentsOfFile File.expand path
  write: (path, contents) ->
    str = OSX.NSString.stringWithString contents
    str.writeToFile_atomically File.expand(path), true
  expand: (path) ->
    if /~/.test path
      OSX.NSString.stringWithString(path).stringByExpandingTildeInPath
    else
      path
  isFile: (path) ->
    isDir = new outArgument
    exists = OSX.NSFileManager.defaultManager.fileExistsAtPath_isDirectory(path, isDir)
    exists and not isDir.valueOf()

Dir =
  list: (path) ->
    path = File.expand path
    _.map OSX.NSFileManager.defaultManager.subpathsAtPath(path), (entry) ->
      "#{path}/#{entry}"
  isDir: (path) ->
    isDir = new outArgument
    exists = OSX.NSFileManager.defaultManager.fileExistsAtPath_isDirectory(path, isDir)
    exists and isDir.valueOf()

Process =
  cwd: (path) ->
    if dir?
      OSX.NSFileManager.defaultManager.changeCurrentDirectoryPath(path)
    else
      OSX.NSFileManager.defaultManager.currentDirectoryPath()

  env: ->
    OSX.NSProcess.processInfo.environment()

# Need to rename and move stuff like this
Project =
  toggle: ->
    frameset = top.document.getElementsByTagName("frameset")[0]
    if @showing
      frameset.removeChild(frameset.firstChild)
      frameset.setAttribute('cols', '*')
    else
      frame = document.createElement("frame")
      frame.src = 'project.html'
      frameset.insertBefore(frame, frameset.firstChild)
      frameset.setAttribute('cols', '25%, *')

    @showing = not @showing

exports ?= this

exports.Chrome = Chrome
exports.File = File
exports.Dir = Dir
exports.Project = Project
