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

NSData *colorizeURL(CFBundleRef bundle, CFURLRef url, int *status, int thumbnail)
{
    NSData *output = NULL;
    unsigned char *targetBuf = malloc(PATH_MAX);
    unsigned char *rsrcDirBuf = malloc(PATH_MAX);
    char *thumbString;
    CFURLRef rsrcDirURL = CFBundleCopyResourcesDirectoryURL(bundle);
    
    if (!CFURLGetFileSystemRepresentation(url, YES, targetBuf, PATH_MAX)
        || !CFURLGetFileSystemRepresentation(rsrcDirURL, YES, rsrcDirBuf, PATH_MAX)) 
    {
        NSLog(@"QLColorCode: CFURLGetFileSystemRepresentation failed");
        *status = 1;
        goto done;
    }
    if (thumbnail)
        thumbString = "1";
    else
        thumbString = "0";
    NSString *cmd = [NSString stringWithFormat:
                     @"\"%s/colorize.sh\" \"%s\" \"%s\" %s", 
                     rsrcDirBuf, rsrcDirBuf, targetBuf, thumbString];
    
    output = runTask(cmd, status);
    if (*status != 0) {
        NSLog(@"QLColorCode: colorize.sh failed with exit code %d", *status);
    }
done:
    free(targetBuf);
    free(rsrcDirBuf);
    return output;
}
