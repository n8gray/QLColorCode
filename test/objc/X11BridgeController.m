
#import "X11BridgeController.h"
#import "ForeignWindow.h"
#import "CGSPrivate.h"

#import <X11/Xmu/WinUtil.h>     /* For XmuClientWindow */
#import <unistd.h>
/* #define XP_NO_X_HEADERS
#import <Xplugin.h> */

@implementation X11BridgeController


/*****************************************************************************
 * Debugging and logging macros
 */
//#define DEBUG_X11
#ifdef DEBUG_X11
#define LOG(cmd) cmd
#else
#define LOG(cmd) do {} while(0)
#endif

//#define SILENT_X11
#ifdef SILENT_X11
#define ERR(cmd) do {} while(0)
#else
#define ERR(cmd) cmd
#endif


/***************************************************************************
** Plugin Methods
*/
- (NSString*) name { return @"X11 Bridge"; }
- (NSString*) description { return @"Integrate Desktop Manager with X11."; }
- (int) interfaceVersion { return 1; }
- (NSBundle*) preferencesBundle { return nil; }

/***************************************************************************
** Global variables (gasp!)
*/

DMController *mDMController;
WorkspaceController *mWSController;    

Display *Disp;
Window Root;

NSMutableDictionary *x11_of_native, *native_of_x11;

Atom net_supported;
/* Atom net_supporting_wm_check; */
Atom net_current_desktop;
Atom net_number_of_desktops;
/* Atom net_desktop_names;
Atom net_desktop_layout; */
Atom net_wm_desktop;
/* Atom net_wm_state_sticky;
Atom wm_state; */
Atom native_window_id;

/*****************************************************************************
 * Utility Macros
 */
#define SET_CARD32(win,atom,valuePtr) XChangeProperty(Disp, (win), \
                                      (atom), XA_CARDINAL, 32, \
                                      PropModeReplace, (unsigned char *)(valuePtr), 1)
#define SET_DESKTOP(n) \
    do { unsigned int v = (n); \
         SET_CARD32( Root, net_current_desktop, &v ); } while (0)
#define SET_WIN_DESKTOP(win,n) \
    do { unsigned int v = (n); \
         SET_CARD32( (win), net_wm_desktop, &v ); } while (0)

/*****************************************************************************
 * X11 Error handlers
 */

/* Define our own error handlers that don't crash DM */
int xErrHandler( Display *d, XErrorEvent *error ) {
    char message[1024];
    XGetErrorText(d, error->error_code, message, 1024);
    message[1023] = '\0';
    ERR(NSLog( @"%s", message ));
    return 0;
}

/* 
 * For some reason this often gets called twice when the server dies.  
 * Surprisingly, it all works out ok despite that.
 */
int ioErrHandler( Display *d ) {
    Disp = NULL;
    ERR(NSLog( @"X11BridgeController: I/O Error.  Perhaps the X Server Died.\n" ));
    @throw( @"X11 IO Error" );
}

/*****************************************************************************
 * Utility functions
 */

/*
 * Intern all the atoms we'll need
 */
void intern_atoms()
{
    net_supported = 
    XInternAtom(Disp, "_NET_SUPPORTED", False);
    /* net_supporting_wm_check = 
    XInternAtom(Disp, "_NET_SUPPORTING_WM_CHECK", False); */
    net_current_desktop = 
        XInternAtom(Disp, "_NET_CURRENT_DESKTOP", False);
    net_number_of_desktops = 
        XInternAtom(Disp, "_NET_NUMBER_OF_DESKTOPS", False);
    /* net_desktop_names = 
        XInternAtom(Disp, "_NET_DESKTOP_NAMES", False);
    net_desktop_layout = 
        XInternAtom(Disp, "_NET_DESKTOP_LAYOUT", False); 
    net_wm_state_sticky = 
        XInternAtom(Disp, "_NET_WM_STATE_STICKY", False); 
    */
    net_wm_desktop = 
        XInternAtom(Disp, "_NET_WM_DESKTOP", False);
    /* wm_state = 
        XInternAtom(Disp, "WM_STATE", False); */
    /* This atom is supported by X11.app and XDarwin.app, which is very good
        for us! */
    native_window_id = 
        XInternAtom(Disp, "_NATIVE_WINDOW_ID", False);
}

Window x11_window_of_native_window( CGSWindow w_native ) {
    NSValue *v_native = 
            [NSValue value:&w_native withObjCType:@encode(CGSWindow)];
    NSValue *v_x11 = [x11_of_native objectForKey:v_native];
    
    /* It's a shame this doesn't work.
    {
    xp_window_id winid;
    xp_bool status;
    status = xp_lookup_native_window( (unsigned int)w_native, &winid );
    LOG(NSLog(@"xp_lookup_native_window: lookup %u -> %d, 0x%x\n", 
            (unsigned int)w_native, status, (unsigned int)winid));
    } */
    
    if (!v_x11)
        return 0;
    Window w;
    [v_x11 getValue:(void *)(&w)];
    return w;
}

CGSWindow native_window_of_x11_window( Window w ) {
    Window w_dummy, *wins, found=(Window)0, parent, w_orig = w;
    unsigned int n_wins;
    Atom type;
    int format;
    unsigned long n_items, bytes_after;
    CGSWindow *win_id_ptr;

    
    XGrabServer(Disp);

    /* It's a shame this doesn't work.
    {
    unsigned int natid;
    xp_bool status;
    status = xp_get_native_window( (xp_window_id)w, &natid );
    LOG(NSLog(@"xp_get_native_window: lookup 0x%x -> %d, %d\n", 
            (unsigned int)w, status, (unsigned int)natid));
    } */
    
    for (; w != Root && !found; w = parent) {
        if (XQueryTree( Disp, w, &w_dummy, &parent, &wins, &n_wins )) {
            if (n_wins)
                XFree(wins);
            
            n_items = 0;
            //NSLog(@"0x%x", wins[i]);
            XGetWindowProperty( Disp, parent, native_window_id, 0, 1, False, 
                                AnyPropertyType, &type, &format, &n_items, 
                                &bytes_after, (unsigned char **)(&win_id_ptr) );
            if (n_items) {
                /* native_window_id property was read */
                //NSLog(@"=  %d", *win_id_ptr);
                found = *win_id_ptr;
                XFree(win_id_ptr);
            }
        } else {
            ERR(NSLog(@"X11BridgeController: XQueryTree failed\n"));
            XUngrabServer(Disp);
            return 0;
        }
    }
    if (!found) {
        LOG(NSLog(@"X11BridgeController: Failed to find native window for "
                  @"window 0x%x", w_orig));
    }
    
    XUngrabServer(Disp);
    return found;
}

void add_to_window_map( Window w ) {
    NSValue *n_native, 
    *n_x11 = [NSValue value:&w withObjCType:@encode(Window)];
    if (![native_of_x11 objectForKey:n_x11]) {
        CGSWindow native;
        if ((native = native_window_of_x11_window( w ))) {
            LOG(NSLog(@"Adding 0x%x <-> %d\n", w, native));
            n_native = [NSValue value:&native withObjCType:@encode(CGSWindow)];
            
            // Put the windows in both maps
            [native_of_x11 setObject:n_native forKey:n_x11];
            [x11_of_native setObject:n_x11 forKey:n_native];
        }
    }
}

void delete_from_window_map( Window w ) {
    NSValue *n_native, 
    *n_x11 = [NSValue value:&w withObjCType:@encode(Window)];
    LOG(NSLog(@"Deleting 0x%x\n", w));
    n_native = [native_of_x11 objectForKey:n_x11];
    if (n_native) {
        [x11_of_native removeObjectForKey:n_native];
        [native_of_x11 removeObjectForKey:n_x11];
    }
}

int init_window_atoms(int nWorkspaces, int currentWorkspace) {
    Window w, dummy_w, *wins;
    unsigned int i,nwins;
    Atom root_atoms[] = {net_wm_desktop, net_current_desktop, 
        net_number_of_desktops};
    CGSConnection conn;
    
    SET_CARD32(Root, net_number_of_desktops, &nWorkspaces);
    SET_DESKTOP(currentWorkspace);
    XChangeProperty(Disp, Root, net_supported, XA_ATOM, 32, PropModeAppend,
                    (unsigned char *)(&root_atoms[0]), 3);
    
    XGrabServer( Disp );
    if (!XQueryTree(Disp, Root, &dummy_w, &dummy_w, &wins, &nwins)) {
        XUngrabServer( Disp );
        return 0;
    }
    
    conn = _CGSDefaultConnection();
    for (i=0; i<nwins; ++i) {
        w = XmuClientWindow(Disp, wins[i]);
        if ( w != wins[i] ) {
            CGSWindow cw;
            add_to_window_map( w );
            cw = native_window_of_x11_window( w );
            CGSGetWindowWorkspace(conn, cw, &currentWorkspace);
            SET_WIN_DESKTOP( w, currentWorkspace-1 );
            XSelectInput(Disp, w, StructureNotifyMask);
            LOG(NSLog( @"Initializing window 0x%x on desktop %d\n",
                       w, currentWorkspace-1 ));
        } else {
            LOG(NSLog( @"No client window for window 0x%x.\n", 
                       (unsigned int)wins[i] ));
        }
    }
    XUngrabServer(Disp);
    if (nwins)
        XFree(wins);
    return 1;
}

/*****************************************************************************
 * X11 Event Handlers
 */

// This handles windows that have been iconified then uniconified
void handle_MapNotify( XEvent *event ) {
    XMapEvent *e = (XMapEvent *)event;
    Window w = e->event;
    
    if (w != Root) {
        unsigned int currentWS = [mWSController currentWorkspaceIndex];
        LOG(NSLog( @"X11BridgeController: MapNotify event for window 0x%x.\n", 
                   (unsigned int)w ));
        SET_WIN_DESKTOP( w, currentWS );
        add_to_window_map( w );
    } else {
        /* LOG(NSLog( @"X11BridgeController: "
                    @"Ignoring Root MapNotify event for 0x%x.\n", 
                   (unsigned int)e->window )) */
        ;
    }
}

// This handles newly created or displayed windows
void handle_ReparentNotify( XEvent *event ) {
    XReparentEvent *e = (XReparentEvent *)event;
    Window w = e->window;
    unsigned int currentWS = [mWSController currentWorkspaceIndex];
    
    LOG(NSLog( @"ReparentNotify: New Parent = 0x%x, Window = 0x%x, "
               @"override_redirect = %d\n", 
           e->parent, w, e->override_redirect ));
    if ( e->parent != Root ) {
        SET_WIN_DESKTOP( w, currentWS );
        // We want to know when this window gets mapped/unmapped
        XSelectInput(Disp, w, StructureNotifyMask);
        // This may fail, but if it does then the MapNotify will get it.
        // If it succeeds then it would have been too late to catch the 
        // MapNotify.  Thus we (probably) need both.
        add_to_window_map( w );
    }
}

void handle_UnmapNotify( XEvent *event ) {
    XUnmapEvent *e = (XUnmapEvent *)event;
    Window w = e->event;
    
    if ( w != Root ) {
        LOG(NSLog( @"X11BridgeController: %s UnmapNotify event for window "
                   @"0x%x.\n", 
                   (e->send_event ? "Synthetic" : ""), (unsigned int)w ));
        XDeleteProperty( Disp, w, net_wm_desktop );
        delete_from_window_map( w );
    } else {
        /* LOG(NSLog( @"X11BridgeController: "
                      @"Ignoring Root UnmapNotify event for 0x%x.\n", 
                   (unsigned int)e->window )) */ 
        ;
    }
}

/*****************************************************************************
 * The X11 Monitor thread
 */
- (void) startX11MonitorThread: (id)argument {
    char *dispName;
    NSAutoreleasePool *arp = [[NSAutoreleasePool alloc] init];
    
    if (!XInitThreads()) {
        ERR(NSLog(@"X11BridgeController: "
                  @"Couldn't initialize multithreaded Xlib.\n"));
        return;
    }
    
    XSetErrorHandler(xErrHandler);
    XSetIOErrorHandler(ioErrHandler);
    
    /* XXX: We should allow another way to set this, like a file or a dialog */
    if (!(dispName = getenv("DISPLAY")))
        dispName = ":0";
    
    x11_of_native = [NSMutableDictionary dictionaryWithCapacity:128];
    native_of_x11 = [NSMutableDictionary dictionaryWithCapacity:128];

    /* {
    xp_error err;
    err = xp_init( XP_IN_BACKGROUND );
    if( !err )
        LOG(NSLog(@"Error on xp_init: %u\n", err));
    } */
    
    while( 1 ) {
        LOG(NSLog(@"Waiting for connection to X Server\n"));
        Disp = NULL;
        
        [x11_of_native removeAllObjects];
        [native_of_x11 removeAllObjects];
        
        @try {
            while (!Disp) {
                Disp = XOpenDisplay(dispName);
                //NSLog(@"X11BridgeController: cannot open display\n");
                if(!Disp)
                    sleep(1);
            }
            LOG(NSLog(@"Opened connection to X Server\n"));
            Root = DefaultRootWindow(Disp);
            
            /* Ask for notification whenever a child of the root window is 
                reparented, mapped, or unmapped */
            XSelectInput(Disp, Root, SubstructureNotifyMask);
            
            // Initialize the atoms on Root and windows that exist now.
            intern_atoms();
            if (!init_window_atoms( [mWSController workspaceCount], 
                                    [mWSController currentWorkspaceIndex] )) {
                ERR(NSLog(@"X11BridgeController: Error setting up root atoms\n"));
                return;
            }
            
            while ( 1 ) {
                XEvent event;
                NSAutoreleasePool *arp2 = [[NSAutoreleasePool alloc] init];
                
                XNextEvent(Disp, &event);
                
                XLockDisplay(Disp);
                switch (event.type) {
                    case UnmapNotify:
                        handle_UnmapNotify(&event);
                        break;
                    case MapNotify:
                        handle_MapNotify(&event);
                        break;
                    case ReparentNotify:
                        handle_ReparentNotify(&event);
                        break;
                    default:
                        break;
                }
                XUnlockDisplay(Disp);
                [arp2 release];
            }
            
        } @catch( id ex ) {
            // If the server exits we should end up here.
            ;
        }
    
        // XCloseDisplay(Disp);  We never do this voluntarily.
    }
    [arp release];
}

/*****************************************************************************
 * DM Event handlers
 */

/*
 * React to a change of workspace by setting the proper atom on X11's root
 * window.
 */
- (void) setRootWorkspace: (NSNotification *)n {
    int ws;
    if (!Disp)
        return;
    ws = [mWSController currentWorkspaceIndex];
    @try {
        XLockDisplay( Disp );
        SET_DESKTOP( ws );
        XUnlockDisplay( Disp );
    } @catch( id ex ) {
        return;
    }
}

- (void) handleWindowWarp: (NSNotification *)n {
    ForeignWindow *fw;
    NSString *owner;
    
    if (!Disp)
        return;
    
    fw = [n object];
    owner = [fw ownerName];
    /* XXX: These should be in a plist */
    if ( [owner compare:@"X11"] == NSOrderedSame 
         || [owner compare:@"XDarwin"] == NSOrderedSame ) {
        int ws_index = [fw workspaceNumber] - 1;
        CGSWindow native_w = [fw windowNumber];
        Window w = (Window)0;
        
        LOG(NSLog(@"Window #%d (%@) warped to workspace %d.\n", 
              native_w, owner, ws_index));
        @try {
            XLockDisplay(Disp);
            if (( w = x11_window_of_native_window(native_w) )) {
                LOG(NSLog(@" -- X11 window: 0x%x\n", w));
                SET_WIN_DESKTOP( w, ws_index );
            } else {
                ERR(NSLog(@"Couldn't convert native window %u to X11 window.\n",
                          (unsigned int)native_w));
            }
            XUnlockDisplay(Disp);
        } @catch( id ex ) {
            return;
        }
    }
}

#define X11_DESKTOP_STICKY 0xFFFFFFFFL
- (void) handleWindowSticky: (NSNotification *)n {
    ForeignWindow *fw;
    NSString *owner;
    
    if (!Disp)
        return;
    
    fw = [n object];
    owner = [fw ownerName];
    if ( [owner compare:@"X11"] == NSOrderedSame 
         || [owner compare:@"XDarwin"] == NSOrderedSame ) {
        @try {
            CGSWindow native_w = [fw windowNumber];
            Window w = (Window)0;
            
            XLockDisplay(Disp);
            if (( w = x11_window_of_native_window(native_w) )) {
                long desktop = X11_DESKTOP_STICKY;
                LOG(NSLog(@" -- X11 window: 0x%x\n", w));
                SET_WIN_DESKTOP( w, desktop );
            } else {
                ERR(NSLog(@"Couldn't convert native window %u to X11 window.\n",
                          (unsigned int)native_w));
            }
            XUnlockDisplay(Disp);
        } @catch( id ex ) {
            return;
        }
    }
}

- (void) pluginLoaded: (DMController*) controller withBundle: (NSBundle*) thisBundle {
    mDMController = controller;
    mWSController = [controller workspaceController];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    
    // Start up the thread that monitors for X11 Events
    [NSThread detachNewThreadSelector:@selector(startX11MonitorThread:)
                             toTarget:self 
                           withObject:nil];
    
    // Register for workspace switch events
    // This needs to be done in this thread because notifications are always
    // delivered in the same thread they're sent from.
    [nc addObserver: self
           selector: @selector(setRootWorkspace:)
               name: NOTIFICATION_WORKSPACESELECTED object: nil];
    
    // Register for window warp events
    [nc addObserver: self
           selector: @selector(handleWindowWarp:)
               name: NOTIFICATION_WINDOWWARPED object: nil];
    
    // Register for window sticky events
    /* Actually, sticky windows work ok for now.  They don't get
        set to desktop 0xFFFFFFFF, but they always get set to the current 
        desktop.  Later I should fix this, but it's a bit tricky.
    [nc addObserver: self
           selector: @selector(handleWindowSticky:)
               name: NOTIFICATION_WINDOWSTICKY object: nil];
    [nc addObserver: self
           selector: @selector(handleWindowWarp:)  // Yes, that's right
               name: NOTIFICATION_WINDOWUNSTICKY object: nil];
    */
    
}

@end
