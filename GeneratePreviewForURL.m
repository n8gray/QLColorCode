/* This code is licensed under the GPL v2.  See LICENSE.txt for details. */

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>

#import <limits.h>  // PATH_MAX


/* -----------------------------------------------------------------------------
 Generate a preview for file
 
 This function's job is to create preview for designated file
 ----------------------------------------------------------------------------- */

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
    
    /* NSString *string;
     string = [[NSString alloc] initWithData: data
     encoding: NSUTF8StringEncoding]; */
    
    *exitCode = [task terminationStatus];
    [task release];
    /* [data release]; */
    /* The docs claim this isn't needed, but we leak descriptors otherwise */
    [file closeFile];
    /*[pipe release];*/
    
    return data;
}


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, 
                               CFURLRef url, CFStringRef contentTypeUTI, 
                               CFDictionaryRef options)
{
    if (QLPreviewRequestIsCancelled(preview))
        return noErr;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // Invoke colorize.sh
    unsigned char *targetBuf = malloc(PATH_MAX);
    unsigned char *rsrcDirBuf = malloc(PATH_MAX);
    CFBundleRef bundle = QLPreviewRequestGetGeneratorBundle(preview);
    CFURLRef rsrcDirURL = CFBundleCopyResourcesDirectoryURL(bundle);
    
    if (!CFURLGetFileSystemRepresentation(url, YES, targetBuf, PATH_MAX)
        || !CFURLGetFileSystemRepresentation(rsrcDirURL, YES, rsrcDirBuf, PATH_MAX)) 
    {
        NSLog(@"QLColorCode: CFURLGetFileSystemRepresentation failed");
        goto done;
    }
    NSString *cmd = [NSString stringWithFormat:
                     @"\"%s/colorize.sh\" \"%s\" \"%s\"", 
                     rsrcDirBuf, rsrcDirBuf, targetBuf];
    
    int status;
    NSData *output = runTask(cmd, &status);
    
    if (status != 0) {
        NSLog(@"QLColorCode: colorize.sh failed with exit code %d", status);
        //goto done;
    }
    if (QLPreviewRequestIsCancelled(preview))
        goto done;
    // Now let WebKit do its thing
    //NSLog(@"**************** Passing the data along **********************");
    CFDictionaryRef emptydict = 
            (CFDictionaryRef)[[[NSDictionary alloc] init] autorelease];
    QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)output, 
                                          //kUTTypePlainText,
                                          kUTTypeHTML, 
                                          emptydict);
    
done:
    free(targetBuf);
    free(rsrcDirBuf);
    [pool release];
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
