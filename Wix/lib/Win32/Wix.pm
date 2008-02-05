package Win32::Wix;

# Module loader and main documentation

use 5.006;
use strict;
use File::Which  ();
use File::Remove ();
use Params::Util '_STRING';
use IPC::Run3    ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Win32::Wix::File     ();
use Win32::Wix::Property ();
use Win32::Wix::Script   ();
use Win32::Wix::Compiler ();
use Win32::Wix::Element  ();
use Win32::Wix::Node     ();

1;
