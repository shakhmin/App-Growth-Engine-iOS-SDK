#define RINGFULDOMAIN @"yogalens.com"
#define DB_FILENAME @"schema.sqlite"

#define kOAuthConsumerKey @""
#define kOAuthConsumerSecret @""
#define kFbAppId @"194729977246633"

#define BARBUTTON(TITLE, STYLE, SELECTOR) [[[UIBarButtonItem alloc] initWithTitle:TITLE style:STYLE target:self action:SELECTOR] autorelease]
#define SYSBARBUTTON(STYLE, SELECTOR) [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:STYLE target:self action:SELECTOR] autorelease]
#define IMGBARBUTTON(IMAGE, STYLE, SELECTOR) [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:IMAGE] style:STYLE target:self action:SELECTOR] autorelease]
