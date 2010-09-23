--
--  PenPressurizerAppDelegate.applescript
--  PenPressurizer
--
--  Created by Eric Nitardy on 8/23/10.
--  Copyright 2010. All rights reserved.
-- See license.txt file for details.


script PenPressurizerAppDelegate -- NSApp
	property parent : class "NSObject"
	
	-- IBOutlets	
	-- Interface Builder considers an outlet as any
	-- property with "missing value" as its value
	
	-- floatingWindow is connected to Bézier view's window
	property floatingWindow : missing value
	
	-- Set the floatingWindow to float above all other windows
	on applicationWillFinishLaunching_(aNotification)
		floatingWindow's setLevel_(1) -- "NSFloatingWindowLevel" = 1		
	end applicationWillFinishLaunching_
	
	-- Set app to TerminateAfterLastWindowClosed
	on applicationShouldTerminateAfterLastWindowClosed_(sender)
		return true
	end applicationShouldTerminateAfterLastWindowClosed_
	
	on applicationShouldTerminate_(sender)
		return current application's NSTerminateNow
	end applicationShouldTerminate_
	
end script