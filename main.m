//
//  main.m
//  PenPressurizer
//
//  Created by Eric Nitardy on 8/23/10.
//  Copyright 2010. All rights reserved.
//	See license.txt file for details.

#import <Cocoa/Cocoa.h>
//#import <AppKit/NSGraphicsContext.h>
//#import <Foundation/NSAffineTransform.h>
#import <AppleScriptObjC/AppleScriptObjC.h>

int main(int argc, char *argv[])
{
	[[NSBundle mainBundle] loadAppleScriptObjectiveCScripts];

	return NSApplicationMain(argc, (const char **) argv);
}
