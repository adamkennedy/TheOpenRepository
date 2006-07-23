#! /usr/bin/perl -w

#############################################################################
## Author:      Herbert Breunung, Maik Glatki, Wanja Chresta
## Purpose:     PCE Starter, Checking Directories
## Created:     06/1/2005
## Copyright:   (c) Herbert Breunung, Maik Glatki, Wanja Chresta
## Licence:     GPL
#############################################################################

use strict;
use File::Spec ();

use vars qw{$VERSION $STANDALONE};
my %pathes;
BEGIN{
	$VERSION = "0.66";

	# Is this the standalone Win32 implementation
	$STANDALONE = 1;

	%pathes = (
		config => 'config/',
		help   => 'help/',
	);

	if  ($^O eq 'MSWin32') {
		push @INC, ( 'pre/lib', 'pre/cpan', 'src' );
		my @filenameparts = split( /\\/, __FILE__ );
		my $destination_dir;
		$destination_dir .= "$filenameparts[$_]/" for ( 0 .. $#filenameparts - 2 );
		if ($destination_dir) {
			$pathes{config} = $destination_dir.$pathes{config};
			$pathes{help}   = $destination_dir.$pathes{help};
			chop $destination_dir;
			chdir $destination_dir;
		} else {
		}
	}
	elsif ($^O eq 'linux') {

		#Makefile.PL configuration:
		my $name    = '<name>';
		my $libdir  = '<libdir>';
		my $sharedir= '<sharedir>';
		my $confdir = '<confdir>';
		#Makefile.Pl configuration end

		my $localconf = $ENV{HOME} . '/.' . $name;
		unless ( -e $localconf && -d $localconf ) {
			require File::Copy;    # default package
			require File::Copy::Recursive; #qw(dircopy)
			File::Copy::Recursive::dircopy( $confdir, $localconf ) or die $!;
		}
		$pathes{config} = $localconf . '/';
		$pathes{help}   = $sharedir . '/help/';
		push @INC, $libdir;
	}
}

use Benchmark ();
my $t0;
BEGIN { $t0 = Benchmark->new; }

use PCE;
use File::HomeDir ();

print "XPR loaded in: ",
	Benchmark::timestr( Benchmark::timediff( Benchmark->new, $t0 ) ), "\n";

	# set directory locations
	$PCE::internal{path}{config}            = $pathes{config};
	$PCE::internal{path}{help}              = $pathes{help};
	$PCE::internal{path}{user}              = $ENV{HOME};
	# set locations of boot files
	$PCE::internal{file}{config}{auto}      = 'global/autosaved.conf';
	$PCE::internal{file}{config}{default}   = 'global/default.conf';
	$PCE::internal{file}{img}{splashscreen} = 'icon/splash/wx_perl_splash.jpg'; # has to be jpeg

# make config files acessable
push @INC, $PCE::internal{path}{config};

# first splashscreen without caution to app but fast
#use Wx::Perl::SplashFast ($pathes{config}.'icon/splash/wx_perl_splash.jpg', 150) ;

# starter for the main app
PCE->new->MainLoop;