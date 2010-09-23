--
-- BezierView.applescript
-- PenPressurizer
--
-- Created by Eric Nitardy on 8/25/10.
-- Copyright 2010. All rights reserved.
-- See license.txt file for details.

global backgroundColor, gridColor, linesColor, minPress, maxPress, pressLevels, hardness, controlPt, penButton, prefFilePath, prefFileName, PenTabletDriverName

--property NSGraphicsContext : class "NSGraphicsContext" 
property NSAffineTransform : class "NSAffineTransform"
property NSBezierPath : class "NSBezierPath"
property NSColor : class "NSColor"


script BezierView
	property parent : class "NSView"
	
	-- "Stylus Button" popup button
	property buttonButton : missing value -- NSPopUpButton
	
	-- "Button Feel", "Min. Pressure", "Max. Pressure" sliders:
	property hardnessSlider : missing value -- NSSlider
	property minPressSlider : missing value
	property maxPressSlider : missing value
	
	
	on initWithFrame_(frame) -- First handler to run
		
		-- Determine tablet driver's correct application name. Two methods provided.
		-- First if process is running, second if not.
		tell application "System Events"
			set tabletDrivers to every process whose (name contains "TabletDriver" and name is not "TabletDriver")
		end tell
		if tabletDrivers is {} then
			-- tablet driver process is not running, so ...
			try
				set tabletPath to path to application "TabletDriver"
				tell application "Finder"
					set tabletApp to name of folder of folder of folder of tabletPath
				end tell
				set PenTabletDriverName to name of application tabletApp
				tell application PenTabletDriverName to launch
				
			on error -- Both methods for finding tablet driver's app name failed, so ...
				tell current application
					activate
					display alert "No TabletDriver running." message "Perhaps this system is not attached to a Wacom Pen Tablet. Nonetheless, this Application cannot launch." as warning
				end tell
				current application's NSApp's terminate_(me)
			end try
			
		else -- tablet driver process IS running, so ...
			set PenTabletDriverName to name of item 1 of tabletDrivers
		end if
		
		-- Find Wacom preferences file. If not found, display error.
		set prefFileName to "com.wacom.pentablet.prefs"
		set prefFilePath to getprefFilePath(prefFileName)
		if prefFilePath is "not found" then
			tell current application
				activate
				display alert "No PenTablet preference file found." message "Perhaps this system is not attached to a Wacom Pen Tablet. Nonetheless, this Application cannot launch." as warning
			end tell
			current application's NSApp's terminate_(me)
		end if
		
		continue initWithFrame_(frame)
		
		-- Set Bézier view's colors
		set backgroundColor to NSColor's whiteColor
		set gridColor to NSColor's blackColor
		set linesColor to NSColor's blueColor
		return me
	end initWithFrame_
	
	on awakeFromNib() -- Second handler to run
		
		preparePenPrefFile() -- Make tmp files to speed sed's pref file changes
		
		-- Using "Styus Button" value, find controlPt in pref file
		-- Then using controlPt, determine hardness, minPress, maxPress.
		set penButton to (buttonButton's titleOfSelectedItem) as string
		getControlPtFromPenPref(penButton)
		controlPtToHardness(controlPt)
		
		-- Set sliders to correct hardness, minPress, maxPress.
		hardnessSlider's setDoubleValue_(hardness)
		minPressSlider's setDoubleValue_(minPress)
		maxPressSlider's setDoubleValue_(maxPress)
	end awakeFromNib
	
	-- When"Styus Button" changes,
	on changeButtonButton_(sender)
		set penButton0 to (buttonButton's titleOfSelectedItem) as string
		if penButton ≠ penButton0 then
			
			-- Using "Styus Button" value, find controlPt in pref file
			-- Then using controlPt, determine hardness, minPress, maxPress.
			set penButton to penButton0
			preparePenPrefFile()
			getControlPtFromPenPref(penButton)
			controlPtToHardness(controlPt)
			
			-- Set sliders to correct hardness, minPress, maxPress.
			hardnessSlider's setDoubleValue_(hardness)
			minPressSlider's setDoubleValue_(minPress)
			maxPressSlider's setDoubleValue_(maxPress)
			my setNeedsDisplay_(true) -- refresh display
		end if
	end changeButtonButton_
	
	-- When"Min. Pressure" slider changes,
	on changeminPressSlider_(sender)
		set minPress0 to sender's doubleValue()
		if minPress0 ≠ minPress then
			set minPress to minPress0
			if minPress + 5 > maxPress then -- keep Max. Pressure >> Min. Pressure
				set maxPress to minPress + 5
				maxPressSlider's setDoubleValue_(maxPress)
			end if
			my setNeedsDisplay_(true) -- refresh display
		end if
	end changeminPressSlider_
	
	-- When"Max. Pressure" slider changes,
	on changemaxPressSlider_(sender)
		set maxPress0 to sender's doubleValue()
		if maxPress0 ≠ maxPress then
			set maxPress to maxPress0
			if maxPress < 5 then -- keep Max. Pressure >> 0
				set maxPress to 5
				maxPressSlider's setDoubleValue_(maxPress)
			end if
			if minPress + 5 > maxPress then -- keep Max. Pressure >> Min. Pressure
				set minPress to maxPress - 5
				minPressSlider's setDoubleValue_(minPress)
			end if
			my setNeedsDisplay_(true) -- refresh display
		end if
	end changemaxPressSlider_
	
	-- When"Button Feel" (hardness) slider changes,
	on changehardnessSlider_(sender)
		set hardness0 to sender's doubleValue()
		if hardness ≠ hardness0 then
			set hardness to hardness0
			hardnessToControlPt(hardness)
			my setNeedsDisplay_(true) -- refresh display
		end if
	end changehardnessSlider_
	
	---- Info on Wacom's preset control points (0 - 6) ----
	(*
			Wacom Control Points for Pen's Quadratic Bézier Curve
			[Control pt. is 2nd of the 3 points of a Quadratic Bézier Curve]
			[Control pt. is normalized to a 0 to 100 range]
			[going from soft (0) to firm (6)]
			

			0th controlPt : {x:0, y:100} -- dist from y=x :-70.72

			1st controlPt : {x:11.67, y:83.14} -- dist from y=x :-50.54

			2nd controlPt : {x:28, y:66.08} -- dist from y=x :-26.93

			3rd controlPt : {x:45.74, y:50} -- dist from y=x :-3.01

			4th controlPt : {x:62.86, y:32.94} -- dist from y=x : 21.16

			5th controlPt : {x:80.18, y:16.86} -- dist from y=x : 44.77

			6th controlPt : {x:81.14, y:12.94} -- dist from y=x : 48.22
			
			[These points are linearly connected to create a continuous
			range of Bézier curves for 0≤hardness≤7.]
	*)
	
	-- When the "Min. Pressure" Default button is pushed,
	-- set "Min. Pressure" to Wacom's preset based on hardness.
	-- hardness 0 - 6: minPress 4.9, 5.88, 6.86, 7.48, 10, 14.9, 20
	-- linearly connected to create a continuous range
	on pushDefaultButton_(sender) -- NSButton
		if hardness < 1 then
			set minPress to 4.9 * (1 - hardness) + 5.88 * (hardness - 0)
		else if hardness < 2 then
			set minPress to 5.88 * (2 - hardness) + 6.86 * (hardness - 1)
		else if hardness < 3 then
			set minPress to 6.86 * (3 - hardness) + 7.84 * (hardness - 2)
		else if hardness < 4 then
			set minPress to 7.84 * (4 - hardness) + 10 * (hardness - 3)
		else if hardness < 5 then
			set minPress to 10 * (5 - hardness) + 14.9 * (hardness - 4)
		else
			set minPress to 14.9 * (6 - hardness) + 20 * (hardness - 5)
		end if
		minPressSlider's setDoubleValue_(minPress)
		my setNeedsDisplay_(true) -- refresh display
	end pushDefaultButton_
	
	-- Convert hardness into a control point 
	-- using Wacom's preset control points for hardnesses 0 - 6,
	-- linearly connected to create a continuous range.
	on hardnessToControlPt(hardIndex)
		if hardIndex < 1 then
			set controlPtX to 0 * (1 - hardIndex) + 11.67 * (hardIndex - 0)
			set controlPtY to 100 * (1 - hardIndex) + 83.14 * (hardIndex - 0)
		else if hardIndex < 2 then
			set controlPtX to 11.67 * (2 - hardIndex) + 28 * (hardIndex - 1)
			set controlPtY to 83.14 * (2 - hardIndex) + 66.08 * (hardIndex - 1)
		else if hardIndex < 3 then
			set controlPtX to 28 * (3 - hardIndex) + 45.74 * (hardIndex - 2)
			set controlPtY to 66.08 * (3 - hardIndex) + 50 * (hardIndex - 2)
		else if hardIndex < 4 then
			set controlPtX to 45.74 * (4 - hardIndex) + 62.86 * (hardIndex - 3)
			set controlPtY to 50 * (4 - hardIndex) + 32.94 * (hardIndex - 3)
		else if hardIndex < 5 then
			set controlPtX to 62.86 * (5 - hardIndex) + 80.18 * (hardIndex - 4)
			set controlPtY to 32.94 * (5 - hardIndex) + 16.86 * (hardIndex - 4)
		else
			set controlPtX to 80.18 * (6 - hardIndex) + 81.14 * (hardIndex - 5)
			set controlPtY to 16.86 * (6 - hardIndex) + 12.94 * (hardIndex - 5)
		end if
		
		set controlPt to {x:controlPtX, y:controlPtY}
		
	end hardnessToControlPt
	
	-- Convert a control point into a hardness 
	-- using Wacom's preset control points for hardnesses 0 - 6,
	-- linearly connected to create a continuous range.
	on controlPtToHardness(pt)
		set dist to ((pt's x) - (pt's y)) * (2 ^ (-0.5))
		if dist < -50.54 then
			set hardness to 1 * (dist - -70.72) / (70.72 - 50.54)
		else if dist < -26.93 then
			set hardness to 1 * (-26.93 - dist) / (50.54 - 26.93) + 2 * (dist - -50.54) / (50.54 - 26.93)
		else if dist < -3.01 then
			set hardness to 2 * (-3.01 - dist) / (26.93 - 3.01) + 3 * (dist - -26.93) / (26.93 - 3.01)
		else if dist < 21.16 then
			set hardness to 3 * (21.16 - dist) / (21.16 + 3.01) + 4 * (dist - -3.01) / (21.16 + 3.01)
		else if dist < 44.77 then
			set hardness to 4 * (44.77 - dist) / (44.77 - 21.16) + 5 * (dist - 21.16) / (44.77 - 21.16)
		else
			set hardness to 5 * (48.22 - dist) / (48.22 - 44.77) + 6 * (dist - 44.77) / (48.22 - 44.77)
		end if
		if hardness > 7 then set hardness to 7
		if hardness < 0 then set hardness to 0
	end controlPtToHardness
	
	
	-- ReDraw Bézier view
	on drawRect_(dirtyRect)
		
		set |bounds| to my |bounds|()
		--set |bounds| to dirtyRect
		set emptySpace to 10
		
		--set currentContext to NSGraphicsContext's currentContext
		
		--Make translation a NSAffineTransform type object
		set translation to NSAffineTransform's transform
		
		-- rControlPt: ControlPt adjusted for range between minPress and maxPress
		set theRange to (maxPress - minPress) / 100
		set rControlPt to ¬
			{x:(controlPt's x) * theRange + minPress, y:(controlPt's y)}
		-- vControlPt: effective on screen ControlPt — view 200 px (+) wide
		set vControlPt to {x:(rControlPt's x) * 2, y:(rControlPt's y) * 2}
		
		-- Draw background
		set thePath to NSBezierPath's bezierPathWithRect_(|bounds|)
		thePath's setLineWidth_(0.5)
		thePath's stroke()
		backgroundColor's |set|()
		thePath's fill()
		thePath's release()
		
		-- Draw x(Pen Pressure) and y(Tablet Response) axes  
		gridColor's |set|()
		thePath's setLineWidth_(0.75)
		thePath's moveToPoint_({x:2, y:0})
		thePath's lineToPoint_({x:2, y:220})
		thePath's moveToPoint_({x:0, y:2})
		thePath's lineToPoint_({x:250, y:2})
		thePath's stroke()
		thePath's release()
		
		-- Draw Max pressure and Max response grid lines
		thePath's setLineWidth_(0.5)
		thePath's moveToPoint_({x:202, y:0})
		thePath's lineToPoint_({x:202, y:220})
		thePath's moveToPoint_({x:0, y:202})
		thePath's lineToPoint_({x:250, y:202})
		thePath's stroke()
		thePath's release()
		
		-- Draw Pressure-Response curve
		linesColor's |set|()
		set thePath to NSBezierPath's bezierPath
		thePath's moveToPoint_({x:0, y:0})
		thePath's lineToPoint_({x:(minPress * 2) as integer, y:0}) -- to minpress flat
		thePath's ¬
			curveToPoint_controlPoint1_controlPoint2_({x:(maxPress * 2) as integer, y:200}, vControlPt, vControlPt) -- curve from minpress to maxpress
		thePath's lineToPoint_({x:250, y:200}) -- from maxpress flat
		thePath's setLineCapStyle_(1) -- I'm puzzled by the effect of changing this
		thePath's setLineWidth_(3)
		
		-- True origin for pressure curve is (2, 2) — see axes above
		translation's translateXBy_yBy_(2, 2)
		translation's concat()
		thePath's stroke()
		thePath's release()
		
		-- pControlPt: effective pref file ControlPt
		-- adjusted for actual tablet pressure sensitivity (pressLevels)
		set pControlPt to ¬
			{x:((rControlPt's x) / 100 * pressLevels) as integer, y:((rControlPt's y) / 100 * pressLevels) as integer}
		-- pMinPress, pMinPress: effective pref file values
		-- adjusted for actual tablet pressure sensitivity (pressLevels)
		set pMinPress to (minPress / 100 * pressLevels) as integer
		set pMaxPress to (maxPress / 100 * pressLevels) as integer
		-- Adjust PressureCurveControlPoint, LowerPressureThreshold and
		-- UpperPressureThreshold in pen preferences file based on new values of
		-- pMinPress, pMaxPress, pControlPt
		setcontrolPtInPrefFile(pMinPress, pMaxPress, pControlPt)
		
	end drawRect_
	
	-- Find Wacom preferences file. If not found, return "not found"
	-- otherwise return path to file.
	on getprefFilePath(fileName)
		set pLocal to path to preferences from local domain
		set pUser to path to preferences from user domain
		set pUserX to POSIX path of pUser
		set pLocalX to POSIX path of pLocal
		tell application "Finder"
			if exists file fileName in folder pUser then
				set pFilePath to pUserX & fileName
			else if exists file fileName in folder pLocal then
				set pFilePath to pLocalX & fileName
			else
				set pFilePath to "not found"
			end if
		end tell
		return pFilePath
	end getprefFilePath
	
	-- Create new temp file of pen preferences file ("new2")
	-- with line endings translated from Mac to Unix
	-- Part of prep for speeding up sed
	on preparePenPrefFile()
		set tempFile to (POSIX path of (path to temporary items)) & "new2"
		do shell script ¬
			"/bin/cat " & quoted form of prefFilePath & " | /usr/bin/tr \"\\r\" \"\\n\" >" & tempFile
	end preparePenPrefFile
	
	-- Use sed on "new2" temp file to find controlPtData and pressLevelData
	-- for chosen stylus button (tip or eraser)
	-- Then use sed to put markers in new temp file ("new3") 
	-- where data needs to be placed. This file has Mac line endings
	-- and is used with sed to quickly insert new data into pen pref file.
	on getControlPtFromPenPref(buttonName)
		set tempFile to (POSIX path of (path to temporary items)) & "new2"
		set tempFile1 to (POSIX path of (path to temporary items)) & "new3"
		-- Find in file 1st "PressureCurveControlPoint" after button name
		-- and extract controlPtData
		set controlPtData to do shell script ¬
			"/usr/bin/sed -n '/ButtonName " & buttonName & "/,/PressureCurveControlPoint/ s_\\(PressureCurveControlPoint [0-9][0-9]* [0-9][0-9]* [0-9][0-9]* [0-9][0-9]* [0-9][0-9]* [0-9][0-9]*\\)_\\1_p' " & tempFile
		-- Find in file 1st "PressureResolution" after button name
		-- and extract pressLevelData
		set pressLevelData to do shell script ¬
			"/usr/bin/sed -n '/ButtonName " & buttonName & "/,/PressureResolution/ s_\\(PressureResolution [0-9][0-9]*\\)_\\1_p' " & tempFile
		-- Calculate variables with data 
		-- mostly 0 - 100 normalization based on pressLevels
		set pressLevels to (word 2 of pressLevelData) as integer
		set minPress to ((word 2 of controlPtData) as integer) / pressLevels * 100
		set maxPress to ((word 6 of controlPtData) as integer) / pressLevels * 100
		set theRange to (maxPress - minPress) / 100
		set controlPtX to ((word 4 of controlPtData) as integer) / pressLevels * 100
		set controlPtY to ((word 5 of controlPtData) as integer) / pressLevels * 100
		set controlPt to {x:(controlPtX - minPress) / theRange, y:controlPtY}
		-- Insert markers in new Mac line ending file ("new3")
		-- where sed will insert data for changed pref file.
		-- Three sed substitutions.
		do shell script ¬
			"/usr/bin/sed -e '/ButtonName " & buttonName & "/,/PressureCurveControlPoint/ s_\\(PressureCurveControlPoint\\) [0-9][0-9]* [0-9][0-9]* [0-9][0-9]* [0-9][0-9]* [0-9][0-9]* [0-9][0-9]*_\\1 --controlPt goes here--_'  -e '/ButtonName " & buttonName & "/,/UpperPressureThreshold/ s_\\(UpperPressureThreshold\\) [0-9][0-9]*_\\1 --minPressHi goes here--_' -e '/ButtonName " & buttonName & "/,/LowerPressureThreshold/ s_\\(LowerPressureThreshold\\) [0-9][0-9]*_\\1 --minPressLo goes here--_' " & tempFile & " | /usr/bin/tr \"\\n\" \"\\r\" > " & tempFile1
		
	end getControlPtFromPenPref
	
	-- Adjust PressureCurveControlPoint, LowerPressureThreshold and
	-- UpperPressureThreshold in pen preferences file based on new values of
	-- pMinPress, pMaxPress, pControlPt	
	on setcontrolPtInPrefFile(pMinPress, pMaxPress, pControlPt)
		set tempFile1 to (POSIX path of (path to temporary items)) & "new3"
		set tempFile2 to prefFilePath
		
		---- Convert variable values to strings --
		set sPressLevels to pressLevels as string
		if pMinPress ≤ 3 then set pMinPress to 4 -- minimum value
		set sMinPress to pMinPress as string
		-- keep LowerPressureThreshold & UpperPressureThreshold three apart
		set sMinPressHi to (pMinPress + 1) as string
		set sMinPressLo to (pMinPress - 2) as string
		set sMaxPress to pMaxPress as string
		set sPtX to pControlPt's x as string
		set sPtY to pControlPt's y as string
		
		-- Insert data at marker locations in Mac line ending file ("new3")
		-- and result is streamed into Wacom pen preferences file.
		-- Three sed substitutions.
		do shell script ¬
			"/usr/bin/sed -e 's_--controlPt goes here--_" & sMinPress & " 0 " & sPtX & " " & sPtY & " " & sMaxPress & " " & sPressLevels & "_' -e 's_--minPressHi goes here--_" & sMinPressHi & "_' -e 's_--minPressLo goes here--_" & sMinPressLo & "_' " & tempFile1 & " > " & tempFile2
		resetTabletDriver() -- force tablet driver to use new preferences data
	end setcontrolPtInPrefFile
	
	
	-- This handler is a fairly unsophisticated approach to getting the driver to
	-- recognize settings changes, but it's the best I've got so far.
	-- When "Button Feel" (hardness) slider, is re-adjusted repeatedly
	-- and in quick sucession, the driver can freeze or behave oddly.
	-- Force quitting the driver or hitting the Modbook reset button fixes this.
	on resetTabletDriver()
		try
			do shell script "killall " & quoted form of PenTabletDriverName
		on error
			try
				do shell script "killall -9 " & quoted form of PenTabletDriverName
			end try
		end try
		delay 0.2
		tell application PenTabletDriverName to launch
		
	end resetTabletDriver
	
end script