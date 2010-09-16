--
--  PressureCurveAppDelegate.applescript
--  PressureCurve
--
--  Created by Eric Nitardy on 8/23/10.
--  Copyright 2010.
--
global prefFileName


script PressureCurveAppDelegate -- NSApp
	property parent : class "NSObject"
	set prefFileName to "com.wacom.pentablet.prefs1"
	-- IBOutlets
	property floatingWindow : missing value
	
	-- Interface Builder considers an outlet as any
	-- property with "missing value" as its value
	(*
	property hardnessSlider : missing value -- NSSlider
	property minPressSlider : missing value
	property maxPressSlider : missing value
	property aWindow : missing value
	*)
	
	on awakeFromNib()
		--current application's terminate_(current application)
	end awakeFromNib
	
	
	
	on applicationWillFinishLaunching_(aNotification)
		floatingWindow's setLevel_(1) -- "NSFloatingWindowLevel" = 1
		--current application's terminate_(current application)
		set prefFileName to "com.wacom.pentablet.prefs"
		set pLocal to path to preferences from local domain
		set pUser to path to preferences from user domain
		
		tell application "Finder"
			(exists file prefFileName in folder pUser) or (exists file prefFileName in folder pLocal)
		end tell
		if result is false then
			tell current application
				activate
				display alert "No PenTablet preference file found." message "Perhaps this system is not attached to a Wacom Pen Tablet. Nonetheless, this Application can't run." as warning
			end tell
			quit
		end if
		
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminateAfterLastWindowClosed_(sender)
		return true
	end applicationShouldTerminateAfterLastWindowClosed_
	
	on applicationShouldTerminate_(sender)
		-- Insert code here to do any housekeeping before your application quits 
		return current application's NSTerminateNow
	end applicationShouldTerminate_
	
end script