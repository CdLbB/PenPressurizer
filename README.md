PenPressurizer
==============
PenPressurizer is a simple utility for the Mac that provides improved control over your pen tablet's pressure sensitivity. It should work on most Wacom tablets and, of course, the Axiotron Modbook.

How does it do that?
--------------------
It does that by providing more fine-grained control over the pen's apparent hardness than is provided by Wacom's preference settings as well as allowing you to adjust both the minimum pressure required to get the tablet to respond and the pressure required to get maximum tablet response.

![PenPressurizerWindow][]

The interface shows the present setting's effective pen pressure/tablet response curve giving you clear understanding of what the settings are doing. Conveniently, the app runs in a small floating window allowing you to adjust the pen's behavior while using your favorite illustration or drawing program.

Is the code worth looking at?
-----------------------------
That depends. This is my first Cocoa related project, so it is probably not very clever. It is written in [AppleScript-Objective-C][] and the source code is available at [Github][Github CdLbB]. Nonetheless, if you are noobie Mac coder, are curious what AppleScriptObjC can do, or want to improve on Wacom's mediocre software, you may find it interesting. Be aware, however, since it is in AppleScriptObjC, it is Snow Leopard only.

Where's the download?
---------------------
It is hiding. There are a couple stubborn bugs at the moment (see below), so, for the time being, I'm making a binary download available only to members of [Modbookish][Modbookish PP], a Modbook users forum, but, of course, [anyone can join Modbookish][Modbookish Join].

Known bugs
----------
Due to the unsophisticated way that PenPressurizer forces Wacom's tablet driver to recognize changes in pen settings, the cursor may jump briefly after you adjust the settings. Just ignore it. More seriously, if you make a lot of setting readjustments quickly, in rapid succession, the tablet driver may freeze or die. On a Modbook, this can be easily fixed by pressing and holding down the Modbook reset button. I'm not sure what happens on a regular Wacom tablet attached to a Mac. If you experience this issue, let me know.

Who am I?
---------
I'm [Eric Nitardy][Modbookish ericn], and I'm O.K.


[PenPressurizerWindow]: http://dl.dropbox.com/u/6347985/Modbookish/Downloads/PenPressurizer/PenPressurizerWindow.png
[Github CdLbB]: http://github.com/CdLbB/PenPressurizer
[AppleScript-Objective-C]: http://developer.apple.com/library/mac/#releasenotes/ScriptingAutomation/RN-AppleScriptObjC/index.html
[Modbookish PP]: http://modbookish.lefora.com/2010/09/23/penpressurizer-improved-control-over-your-tablets-/
[Modbookish Join]: http://modbookish.lefora.com/gateway/?new_user=True&next=/
[Modbookish ericn]: http://modbookish.lefora.com/members/ericn/