/*
 *  Common.c
 *  QLColorCode
 *
 *  Created by Nathaniel Gray on 12/6/07.
 *  Copyright 2007 Nathaniel Gray. All rights reserved.
 *
 */

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <limits.h>  // PATH_MAX

#include "Common.h"


NSData *runTask(NSString *script, int *exitCode) {
    NSTask *task = [[NSTask alloc] init];
    [task setCurrentDirectoryPath:@"/tmp"];     /* XXX: Fix this */
    //[task setEnvironment:env];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:[NSArray arrayWithObjects:@"-c", script, nil]];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    [task setStandardError: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    [task waitUntilExit];
    
    *exitCode = [task terminationStatus];
    [task release];
    /* The docs claim this isn't needed, but we leak descriptors otherwise */
    [file closeFile];
    /*[pipe release];*/
    
    return data;
}

NSString *pathOfURL(CFURLRef url)
{
    NSString *targetCFS = [[(NSURL *)url absoluteURL] path];
    return [targetCFS stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

NSData *colorizeURL(CFBundleRef bundle, CFURLRef url, int *status, int thumbnail)
{
    NSData *output = NULL;
    CFURLRef rsrcDirURL = CFBundleCopyResourcesDirectoryURL(bundle);
    //n8log(@"rsrcDirURL = %@", CFURLGetString(rsrcDirURL));
    NSString *rsrcEsc = pathOfURL(rsrcDirURL);
    CFRelease(rsrcDirURL);
    NSString *targetEsc = pathOfURL(url);
    
    NSString *cmd = [NSString stringWithFormat:
                     @"\"%@/colorize.sh\" \"%@\" \"%@\" %s", 
                     rsrcEsc, rsrcEsc, targetEsc, thumbnail ? "1" : "0"];
    n8log(@"cmd = %@", cmd);
    
    output = runTask(cmd, status);
    if (*status != 0) {
        NSLog(@"QLColorCode: colorize.sh failed with exit code %d", *status);
    }
    return output;
}
