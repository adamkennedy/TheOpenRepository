#!/usr/bin/perl

# Phase 2 Installer
# -----------------
#
# The second-phase installer does the main RedHat and CPAN dependency
# installation tasks.

use 5.8.5;
use strict;
use Carp ();
use File::Spec::Functions ':ALL';

my $VERBOSE  = 1;
my $SVN_PATH = 'https://svn.ce.corp/projects/netxpress/k2/trunk';

my @RPM_PACKAGES = qw{
        oracle-client
        mod_perl
        gcc
        gdbm-devel
        libxml2-devel
        libxslt-devel
	perl-Compress-Zlib
	perl-Crypt-SSLeay
	perl-DateManip
	perl-DBI
	perl-URI
	perl-XML-Parser
	perl-libwww-perl
};

my @TOOLCHAIN_PACKAGES = qw{
	ExtUtils-MakeMaker-6.36
	File-Path-2.01
	ExtUtils-Command-1.13
 	ExtUtils-Install-1.44
	ExtUtils-Manifest-1.51
	Test-Harness-2.64
	Test-Simple-0.72
	ExtUtils-CBuilder-0.19
	ExtUtils-ParseXS-2.18
	version-0.73
	Scalar-List-Utils-1.19
	IO-Zlib-1.07
	PathTools-3.25
	File-Temp-0.18
	File-HomeDir-0.66
	File-Which-0.05
	Archive-Zip-1.20
	Archive-Tar-1.36
	YAML-0.66
	libnet-1.22
	Digest-MD5-2.36
	Digest-SHA1-2.11
	Digest-SHA-5.45
	Module-Build-0.2808
	CPAN-1.9203
	CPAN-Mini-0.562
};

my @CPAN_MODULES = qw{
	Business::CreditCard
	Carp::Assert::More
	CGI
	CGI::Cookie
	CGI::Util
	Class::Inspector
	DateTime
	DBD::SQLite
	Devel::Leak::Object
	Digest::MD5
	Error
	File::Remove
	HTML::TokeParser
	HTTP::Server::Simple
	IO::File
	Lingua::Stem::En
	Math::BigInt
	Math::BigFloat
	Math::BigRat
	bignum
	Net::DNS::Resolver
	Object::Tiny
	pler
	Params::Util
	PDF::API2
	Storable
	Sys::CpuLoad
	Sys::Hostname
	Sys::Syslog
	SQL::Script
	Test::LongString
	Test::SubCalls
	Text::Tabs
	Text::Wrap
	Time::HiRes
	Time::Local
	URI::Escape
	WWW::Mechanize
	XML::NamespaceSupport
	XML::SAX
};

my @FORCED_PACKAGES = qw{
	Template-Toolkit-2.19
	Test-WWW-Mechanize-1.14
	XML-LibXML-Common-0.13
	XML-LibXML-1.65
	XML-LibXSLT-1.63
	DBD-Oracle-1.19
};





#####################################################################
# Prepare

# If PERL5LIB is defined BEFORE we start, it can cause big problems
if ( $ENV{PERL5LIB} ) {
	die "This application does not work with PERL5LIB defined";
}

# This needs to be run as root (or sudo)
unless ( $< == 0 ) {
	die "This application must be run as root/sudo";
}

# This should be run from the same directory as the script
use FindBin ();
chdir $FindBin::Bin;
print( (`pwd`)[0] );





#####################################################################
# RedHat Installations

# Install the various rpm packages
foreach my $rpm ( @RPM_PACKAGES ) {
	shell("yum install $rpm");
}





#####################################################################
# Bootstrap The CPAN Environment

# Create the build path
my $PREFIX  = catdir('/opt/cpan');
shell("rm -rf $PREFIX") if -e $PREFIX;
shell("mkdir $PREFIX");
$ENV{PERL5LIB} = catdir( $PREFIX, 'lib', 'perl5' );
require lib;
lib->import(
	catdir( $ENV{PERL5LIB}, 'i386-linux-thread-multi' ),
	$ENV{PERL5LIB}
);

# Always use default options
$ENV{ORACLE_HOME}       ||= '/opt/oracle/10.2';
$ENV{PERL_MM_USE_DEFAULT} = 1;
if ( $ENV{LD_LIBRARY_PATH} ) {
	$ENV{LD_LIBRARY_PATH} .= ':' . catdir($ENV{ORACLE_HOME}, 'lib');
} else {
	$ENV{LD_LIBRARY_PATH} = catdir($ENV{ORACLE_HOME}, 'lib');
}

my $perl_packages = rel2abs(catdir('packages', 'perl'));
unless ( -d $perl_packages ) {
	die "Failed to find perl packages dir '$perl_packages'";
}
foreach my $dir ( @TOOLCHAIN_PACKAGES ) {
	# Prepare to open the tarball
	my $tarball  = $dir . '.tar.gz';
	my $builddir = catdir( $perl_packages, $dir );
	if ( -d $builddir ) {
		shell("rm -rf $builddir");
	}
	SCOPE: {
		my $pushd2 = pushd( $perl_packages );

		# Untar the tarball
		shell( 'tar -zxvf ' . $tarball );
		unless ( -d $dir ) {
			Carp::croak("Failed to extract $tarball");
		}
		chdir $dir or Carp::croak("chdir($dir): $!");

		# Build the package
		shell("perl Makefile.PL INSTALL_BASE=$PREFIX");
		unless ( -f 'Makefile' ) {
			Carp::croak("'perl Makefile.PL' failed for $tarball");
		}
		shell('make');
		unless ( -d 'blib' ) {
			Carp::croak("'make' failed for $tarball");
		}

		# Test the package
		# shell('make test');

		# Install the package
		shell('make install');
	}

	# Clear up the build directory
	if ( -d $builddir ) {
		shell("rm -rf $builddir");
	}
}

# Inject the pre-built configuration
SCOPE: {
	my $from = catfile( 'packages', 'perl', 'CPAN_Config.pm' );
	unless ( -f $from ) {
		die "Failed to find CPAN configuration";
	}
	my $dir = catdir( $ENV{PERL5LIB}, 'CPAN' );
	shell("mkdir $dir") unless -d $dir;
	my $to = catfile( $dir, 'Config.pm' );
	shell("cp $from $to");
}

# Load the CPAN client
require CPAN;

# Install the modules we need
foreach my $module ( @CPAN_MODULES ) {
	CPAN::Shell->install($module);
}

foreach my $dir ( @FORCED_PACKAGES ) {
        # Prepare to open the tarball
        my $tarball  = $dir . '.tar.gz';
        my $builddir = catdir( $perl_packages, $dir );
        if ( -d $builddir ) {
                shell("rm -rf $builddir");
        }
        SCOPE: {
                my $pushd2 = pushd( $perl_packages );

                # Untar the tarball
                shell( 'tar -zxvf ' . $tarball );
                unless ( -d $dir ) {
                        Carp::croak("Failed to extract $tarball");
                }
                chdir $dir or Carp::croak("chdir($dir): $!");

                # Build the package
		my $OPTIONS = "INSTALL_BASE=$PREFIX";
		if ( $dir =~ /Template-Toolkit/ ) {
			$OPTIONS .= ' TT_EXTRAS=n TT_ACCEPT=y';
		}
                shell("perl Makefile.PL $OPTIONS");
                unless ( -f 'Makefile' ) {
                        Carp::croak("'perl Makefile.PL' failed for $tarball");
                }
                shell('make');
                unless ( -d 'blib' ) {
                        Carp::croak("'make' failed for $tarball");
                }

                # Test the package
                # shell('make test');

                # Install the package
                shell('make install');
        }

        # Clear up the build directory
        if ( -d $builddir ) {
                shell("rm -rf $builddir");
        }
}




#####################################################################
# Check out the main project
#
# Step 2 - Checkout the installation svn path
#SCOPE: {
#	my $pushd = pushd( '/opt/netxpress' );
#	shell("rm -rf trunk");
#	shell("svn export $SVN_PATH");
#}
#
#
#
#
#
#####################################################################
# Build the project
#
#SCOPE: {
#	my $pushd = pushd( '/opt/netxpress/trunk' );
#	shell( 'perl Build.PL' );
#	shell( 'perl Build'    );
#}





#####################################################################
# Support Functions

exit(255);

sub sudo {
	shell('sudo ' . $_[0]);
}

sub shell {
	my $command = shift;
	print "> $command\n" if $VERBOSE;
	my $rv = ! system( $command );
	if ( $rv or ! @_ ) {
		return $rv;
	}
	Carp::croak( $_[0] || "Failed to run '$command'" );
}

sub chdir {
	my $dir = shift;
	print "- chdir '$dir'\n" if $VERBOSE;
	return 1 if CORE::chdir $dir;
	Carp::croak( "Failed to change to '$dir'" );
}

sub pushd {
	print "- pushd $_[0]\n";
	My::File::pushd::pushd(@_);
}





#####################################################################
# Bundle a compressed File::pushd

package My::File::pushd;

use Carp       ();
use Cwd        ();
use File::Spec ();

use overload 
    q{""} => sub { File::Spec->canonpath( $_[0]->{_pushd} ) },
    fallback => 1;

sub pushd {
    my ($target_dir) = @_;
    my $orig = Cwd::cwd();
    my $dest = eval { $target_dir ? Cwd::abs_path( $target_dir ) : $orig };
    Carp::croak "Can't locate directory $target_dir: $@" if $@;
    if ($dest ne $orig) { 
        chdir $dest or Carp::croak "Can't chdir to $dest\: $!";
    }
    return bless { 
        _pushd    => $dest,
        _original => $orig
    }, __PACKAGE__;
}

sub DESTROY {
    # should always be so, but just in case...
    chdir $_[0]->{_original} if $_[0]->{_original};
}
