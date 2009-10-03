#!perl -w

use strict;

use Test::More tests => 1;

my $minor = 0;

if ( -f '/usr/bin/sw_vers' && -x _ ) {
    ($minor) = (qx</usr/bin/sw_vers -productVersion> =~ /\A\d+\.(\d+)\.\d+/);
}

my @import = (
    # Functions
    qw( FindDirectory
        HomeDirectory
        TemporaryDirectory
    ),
    # NSSearchPathDomainMask
    qw( NSUserDomainMask
        NSLocalDomainMask
        NSNetworkDomainMask
        NSSystemDomainMask
        NSAllDomainsMask
    ),
    # NSSearchPathDirectory
    qw( NSApplicationDirectory
        NSDemoApplicationDirectory
        NSDeveloperApplicationDirectory
        NSAdminApplicationDirectory
        NSLibraryDirectory
        NSDeveloperDirectory
        NSUserDirectory
        NSDocumentationDirectory
        NSAllApplicationsDirectory
        NSAllLibrariesDirectory
    ),
    ($minor >= 2) ?
    qw( NSDocumentDirectory
    ) : (),
    ($minor >= 3) ?
    qw( NSCoreServiceDirectory
    ) : (),
    ($minor >= 4) ?
    qw( NSDesktopDirectory
        NSCachesDirectory
        NSApplicationSupportDirectory
    ) : (),
    ($minor >= 5) ?
    qw( NSDownloadsDirectory
    ) : (),
    ($minor >= 6) ?
    qw( NSInputMethodsDirectory
        NSMoviesDirectory
        NSMusicDirectory
        NSPicturesDirectory
        NSPrinterDescriptionDirectory
        NSSharedPublicDirectory
        NSPreferencePanesDirectory
        NSItemReplacementDirectory
    ) : ()
);

use_ok('Mac::SystemDirectory', @import);
