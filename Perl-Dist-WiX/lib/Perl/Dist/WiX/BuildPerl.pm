package Perl::Dist::WiX::BuildPerl;

=pod

=head1 NAME

Perl::Dist::WiX::BuildPerl - 4th generation Win32 Perl distribution builder

=head1 VERSION

This document describes Perl::Dist::WiX::BuildPerl version 1.200001.

=head1 DESCRIPTION

This module provides the routines that Perl::Dist::WiX uses in order to
build Perl itself.  

=head1 SYNOPSIS

	# This module is not to be used independently.
	# It provides methods to be called on a Perl::Dist::WiX object.

=head1 INTERFACE

=cut

use 5.008001;
use Moose;
use English qw( -no_match_vars );
use List::MoreUtils qw( any );
use Params::Util qw( _HASH _STRING _INSTANCE );
use Readonly qw( Readonly );
use Storable qw( retrieve );
use File::Spec::Functions qw(
  catdir catfile catpath tmpdir splitpath rel2abs curdir
);
use Module::CoreList 2.32 qw();
use Perl::Dist::WiX::Asset::Perl qw();
use Perl::Dist::WiX::Toolchain qw();
use File::List::Object qw();

our $VERSION = '1.200_100';
$VERSION =~ s/_//sm;

Readonly my %CORE_MODULE_FIX => (
	'IO::Compress'         => 'IO::Compress::Base',
	'Filter'               => 'Filter::Util::Call',
	'Pod'                  => 'Pod::Man',
	'Text'                 => 'Text::Tabs',
	'PathTools'            => 'Cwd',
	'Scalar::List::Utils'  => 'List::Util',
	'Locale::Constants'    => 'Locale::Codes',
	'TermReadKey'          => 'Term::ReadKey',
	'Term::ReadLine::Perl' => 'Term::ReadLine',
	'libwww::perl'         => 'LWP',
	'LWP::UserAgent'       => 'LWP',
);

Readonly my %DIST_TO_MODULE_FIX => (
	'CGI.pm'               => 'CGI',
	'Locale::Maketext'     => 'Locale-Maketext',
	'Pod::Man'             => 'Pod',
	'Text::Tabs'           => 'Text',
	'PathTools'            => 'Cwd',
	'TermReadKey'          => 'Term::ReadKey',
	'Term::ReadLine::Perl' => 'Term::ReadLine',
	'libwww::perl'         => 'LWP',
	'Scalar::List::Utils'  => 'List::Util',
	'libnet'               => 'Net',
	'encoding'             => 'Encode',
	'IO::Scalar'           => 'IO::Stringy',
);

# Modules to delay.
Readonly my @MODULE_DELAY => qw(
  CPANPLUS::Dist::Build
  File::Fetch
  Thread::Queue
);



sub _delay_upgrade {
	my ( $self, $module ) = @_;

	return ( any { $module->id eq $_ } @MODULE_DELAY ) ? 1 : 0;
}



sub _module_fix {
	my ( $self, $module ) = @_;

	return ( exists $CORE_MODULE_FIX{$module} )
	  ? $CORE_MODULE_FIX{$module}
	  : $module;
}



#####################################################################
# CPAN installation and upgrade support

# NOTE: "The object that called it" is supposed to be a Perl::Dist::WiX
# object.

=head2 install_cpan_upgrades

The C<install_cpan_upgrades> method is provided to upgrade all the
modules that were installed with Perl that were not upgraded by the
L<install_perl_toolchain|/install_perl_toolchain> subroutine.

Returns true or throws an exception.

This is recommended to be used as a task in the tasklist, and is in 
the default tasklist after the "perl toolchain" is installed.

=cut

sub install_cpan_upgrades { ## no critic(ProhibitExcessComplexity)
	my $self = shift;

	# Check for Perl - we can't do things out of order.
	if ( not $self->bin_perl() ) {
		PDWiX->throw(
			'Cannot install CPAN modules yet, perl is not installed');
	}

	# Get list of modules to be upgraded.
	# (The list is saved as a Storable arrayref of CPAN::Module objects.)
	my $cpan_info_file = $self->_get_cpan_upgrades_list();
	my $module_info    = retrieve($cpan_info_file);

	# Now go through the loop for each module.
	my $force;
	my @delayed_modules;
	require CPAN;
  MODULE:

	for my $module ( @{$module_info} ) {
		$force = $self->force();

		# Skip modules that we want to skip.
		next MODULE if $self->_skip_upgrade($module);

		# Net::Ping seems to require that a web server be
		# available on localhost in order to pass tests.
		if ( $module->cpan_file() =~ m{/Net-Ping-\d}msx ) {
			$self->_install_cpan_module( $module, 1 );
			next MODULE;
		}

		# Safe seems to have problems inside a build VM, but
		# not outside.  Forcing to be safe.
		if ( $module->cpan_file() =~ m{/Safe-\d}msx ) {
			$self->_install_cpan_module( $module, 1 );
			next MODULE;
		}

		# Locale::Maketext::Simple 0.20 has a test bug. Forcing.
		if (
			$module->cpan_file() =~ m{/Locale-Maketext-Simple-0 [.] 20}msx )
		{
			$self->_install_cpan_module( $module, 1 );
			next MODULE;
		}

		# Time-HiRes is timing-dependent, of course.
		if ( $module->cpan_file() =~ m{/Time-HiRes-}msx ) {
			$self->_install_cpan_module( $module, 1 );
			next MODULE;
		}

		# Module::Install needs a few more modules.
		if (    ( $module->cpan_file() =~ m{/Module-Install-\d}msx )
			and ( $module->cpan_version() > 0.79 ) )
		{
			$self->install_modules(qw( File::Remove YAML::Tiny ));
			$self->_install_cpan_module( $module, $force );
			next MODULE;
		}

		# There's a problem with extracting these two files, so
		# upgrading to these versions, instead...
		if ( $module->cpan_file() =~
			/Unicode-Collate-0 [.] 53-withoutworldwriteables/msx )
		{
			$self->install_distribution(
				name     => 'SADAHIRO/Unicode-Collate-0.53.tar.gz',
				mod_name => 'Unicode::Collate',
				$self->_install_location(1),
				$force
				? ( force => 1 )
				: (),
			);
			next MODULE;
		} ## end if ( $module->cpan_file...)

		if ( $module->cpan_file() =~
			/Unicode-Normalize-1 [.] 06-withoutworldwriteables/msx )
		{
			$self->install_distribution(
				name     => 'SADAHIRO/Unicode-Normalize-1.06.tar.gz',
				mod_name => 'Unicode::Normalize',
				$self->_install_location(1),
				$force
				? ( force => 1 )
				: (),
			);
			next MODULE;
		} ## end if ( $module->cpan_file...)

		# Get rid of the old ExtUtils::MakeMaker files.
		if (    ( $module->cpan_file() =~ m{/ExtUtils-MakeMaker-\d}msx )
			and ( $module->cpan_version() > 6.50 ) )
		{
			$self->remove_file(qw{perl lib ExtUtils MakeMaker bytes.pm});
			$self->remove_file(qw{perl lib ExtUtils MakeMaker vmsish.pm});
			$self->_install_cpan_module( $module, $force );
			next MODULE;
		}

		# The podlators dist needs a few more modules to install on 5.8.9.
		if (    ( $module->cpan_file() =~ m{/podlators-\d}msx )
			and ( $module->cpan_version() > 2.00 )
			and ( $self->perl_version() < 5100 ) )
		{
			$self->install_modules(qw( Pod::Escapes Pod::Simple ));
			$self->_install_cpan_module( $module, $force );
			next MODULE;
		}

		# New CGI.pm versions require FCGI.
		if (    ( $module->cpan_file() =~ m{/CGI [.] pm-\d}msx )
			and ( $module->cpan_version() > 3.45 ) )
		{
			$self->install_modules(qw( FCGI ));
			$self->_install_cpan_module( $module, $force );
			next MODULE;
		}

		# If we're on the "delay this module" list, do so.
		if ( $self->_delay_upgrade($module) ) {
			unshift @delayed_modules, $module;
			next MODULE;
		}

		$self->_install_cpan_module( $module, $force );
	} ## end for my $module ( @{$module_info...})

	# NOW install delayed modules!
	for my $module (@delayed_modules) {
		$self->_install_cpan_module( $module, $force );
	}

	# Getting modules for autodie support installed.
	# Yes, I know that technically it's a core module with
	# non-core dependencies, and that's ugly. I've just got
	# to live with it.
	my $autodie_location = $self->file(qw(perl lib autodie.pm));

	if ( -e $autodie_location ) {
		$self->install_modules(qw( Win32::Process IPC::System::Simple ));
	}

	# Getting CPANPLUS config file installed if required.
	my $cpanp_config_location =
	  $self->file(qw(perl lib CPANPLUS Config.pm));
	if ( -e $cpanp_config_location ) {

		$self->trace_line( 1,
			"Getting CPANPLUS config file ready for patching\n" );

		$self->patch_file(
			'perl/lib/CPANPLUS/Config.pm' => $self->image_dir(),
			{ dist => $self, } );
	}

	# Install dev version of CPAN if we haven't already.
	if ( not $self->fragment_exists('CPAN') ) {
		$self->install_distribution(
			name             => 'ANDK/CPAN-1.94_56.tar.gz',
			mod_name         => 'CPAN',
			makefilepl_param => ['INSTALLDIRS=perl'],
			buildpl_param    => [ '--installdirs', 'core' ],
		);
	}

	return $self;
} ## end sub install_cpan_upgrades

sub _get_cpan_upgrades_list {
	my $self = shift;

	# Get the CPAN url.
	my $url = $self->cpan()->as_string();

	# Generate the CPAN installation script
	my $cpan_string = <<"END_PERL";
print "Loading CPAN...\\n";
use CPAN;
CPAN::HandleConfig->load unless \$CPAN::Config_loaded++;
\$CPAN::Config->{'urllist'} = [ '$url' ];
END_PERL
	$cpan_string .= <<'END_PERL';
print "Loading Storable...\n";
use Storable qw(nstore);

my ($module, %seen, %need, @toget);
	
my @modulelist = CPAN::Shell->expand('Module', '/./');

# Schwartzian transform from CPAN.pm.
my @expand;
@expand = map {
	$_->[1]
} sort {
	$b->[0] <=> $a->[0]
	||
	$a->[1]{ID} cmp $b->[1]{ID},
} map {
	[$_->_is_representative_module,
	 $_
	]
} @modulelist;

MODULE: for $module (@expand) {
	my $file = $module->cpan_file;
	
	# If there's no file to download, skip it.
	next MODULE unless defined $file;

	$file =~ s{^./../}{};
	my $latest  = $module->cpan_version;
	my $inst_file = $module->inst_file;
	my $have;
	my $next_MODULE;
	eval { # version.pm involved!
		if ($inst_file) {
			$have = $module->inst_version;
			local $^W = 0;
			++$next_MODULE unless CPAN::Version->vgt($latest, $have);
			# to be pedantic we should probably say:
			#    && !($have eq "undef" && $latest ne "undef" && $latest gt "");
			# to catch the case where CPAN has a version 0 and we have a version undef
		} else {
		   ++$next_MODULE;
		}
	};

	next MODULE if $next_MODULE;
	
	if ($@) {
		next MODULE;
	}
	
	$seen{$file} ||= 0;
	next MODULE if $seen{$file}++;
	
	push @toget, $module;
	
	$need{$module->id}++;
}

unless (%need) {
	print "All modules are up to date\n";
}
	
END_PERL
	my $cpan_info_file = catfile( $self->output_dir(), 'cpan.info' );
	$cpan_string .= <<"END_PERL";
nstore \\\@toget, '$cpan_info_file';
print "Completed collecting information on all modules\\n";

exit 0;
END_PERL

	# Dump the CPAN script to a temp file and execute.
	$self->trace_line( 1, "Running upgrade of all modules\n" );
	my $cpan_file = catfile( $self->build_dir(), 'cpan_string.pl' );
  SCOPE: {
		my $CPAN_FILE;
		open $CPAN_FILE, '>', $cpan_file
		  or PDWiX->throw("CPAN script open failed: $OS_ERROR");
		print {$CPAN_FILE} $cpan_string
		  or PDWiX->throw("CPAN script print failed: $OS_ERROR");
		close $CPAN_FILE
		  or PDWiX->throw("CPAN script close failed: $OS_ERROR");
	}
	$self->execute_perl($cpan_file)
	  or PDWiX->throw('CPAN script execution failed');
	PDWiX->throw('Failure detected during cpan upgrade, stopping')
	  if $CHILD_ERROR;

	return $cpan_info_file;
} ## end sub _get_cpan_upgrades_list

sub _install_location {
	my ( $self, $core ) = @_;

	# Return the correct location information.
	my $portable = $self->portable();
	if ($core) {
		return (
			makefilepl_param => ['INSTALLDIRS=perl'],
			buildpl_param    => [ '--installdirs', 'core' ],
		);
	} elsif ($portable) {
		return (
			makefilepl_param => ['INSTALLDIRS=site'],
			buildpl_param    => [ '--installdirs', 'site' ],
		);
	} else {
		return (
			makefilepl_param => ['INSTALLDIRS=vendor'],
			buildpl_param    => [ '--installdirs', 'vendor' ],
		);
	}
} ## end sub _install_location



sub _install_cpan_module {
	my ( $self, $module, $force ) = @_;

	# Collect information.
	$force = $force or $self->force();
	my $perl_version = $self->perl_version_literal();
	my $module_id    = $self->_module_fix( $module->id() );
	my $module_file  = substr $module->cpan_file(), 5;
#<<<
	my $core =
	  exists $Module::CoreList::version{ $perl_version }{ $module_id }
	  ? 1
	  : 0;

	# Override core determination for this module.
	# (It's not in core, but other modules that this distribution
	# installs are)
	if ('Locale::Codes' eq $module_id) {
		$core = 1;
	}

	# Actually do the installation.
	$self->install_distribution(
		name     => $module_file,
		mod_name => $module_id,
		$self->_install_location($core),
		$force
		  ? ( force => 1 )
		  : (),
	);
#>>>
	return 1;
} ## end sub _install_cpan_module



sub _skip_upgrade {
	my ( $self, $module ) = @_;

	# DON'T try to install Perl at this point!
	return 1 if $module->cpan_file() =~ m{/perl-5 [.]}msx;

	# DON'T try to install Term::ReadKey, we
	# already upgraded it.
	return 1 if $module->id() eq 'Term::ReadKey';

	# DON'T try to install Win32API::Registry, we
	# already upgraded it as far as we can.
	return 1 if $module->id() eq 'Win32API::Registry';

	# If the ID is CGI::Carp, there's a bug in the index.
	return 1 if $module->id() eq 'CGI::Carp';

	# If the ID is ExtUtils::MakeMaker, we've already installed it.
	# There were some files gotten rid of after 6.50, so
	# install_cpan_upgrades thinks that it needs to upgrade
	# those files using it when using perl versions that
	# still had those files.

	# This code is in here for safety as of yet.
	return 1 if $module->cpan_file() =~ m{/ExtUtils-MakeMaker-6 [.] 50}msx;

	# Skip B::C, it does not install on 5.8.9.
	return 1 if $module->cpan_file() =~ m{/B-C-1 [.]}msx;

	return 0;
} ## end sub _skip_upgrade



#####################################################################
# Perl installation support

=head2 install_perl

The C<install_perl> method is a minimal routine provided to call the 
correct L<install_perl_*|/install_perl_*> routine for the version of perl 
being created.

Returns true or throws an exception.

This is recommended to be used as a task in the tasklist, and is in 
the default tasklist after the "c toolchain" is installed.

=cut

# Just hand off to the larger set of Perl install methods.
sub install_perl {
	my $self = shift;

	# Check for the method, then call it.
	my $install_perl_method = 'install_perl_' . $self->perl_version();
	if ( not $self->can($install_perl_method) ) {
		PDWiX->throw(
			"Cannot generate perl, missing $install_perl_method method in "
			  . ref $self );
	}
	$self->$install_perl_method(@_);

	# Add the perllocal.pod to the perl fragment.
	$self->add_to_fragment( 'perl',
		[ $self->file(qw(perl lib perllocal.pod)) ] );

	return 1;
} ## end sub install_perl



sub _create_perl_toolchain {
	my $self = shift;
	my $cpan = $self->cpan();

	# Quick check for a nonexistent minicpan directory.
	if ( _INSTANCE( $cpan, 'URI::file' ) ) {
		if ( not -d $cpan->dir() ) {
			PDWiX::Directory->throw(
				message =>
				  'Directory referred to by CPAN url does not exist',
				dir => $cpan->dir() );
		}
	}

	# Prefetch and predelegate the toolchain so that it
	# fails early if there's a problem
	$self->trace_line( 1, "Pregenerating toolchain...\n" );
	my $toolchain = Perl::Dist::WiX::Toolchain->new(
		perl_version => $self->perl_version_literal(),
		cpan         => $cpan->as_string(),
		bits         => $self->bits(),
	) or PDWiX->throw('Failed to resolve toolchain modules');
	if ( not eval { $toolchain->delegate(); 1; } ) {
		PDWiX::Caught->throw(
			message => 'Delegation error occured',
			info    => defined($EVAL_ERROR) ? $EVAL_ERROR : 'Unknown error',
		);
	}
	if ( defined $toolchain->get_error() ) {
		PDWiX::Caught->throw(
			message => 'Failed to generate toolchain distributions',
			info    => $toolchain->get_error() );
	}

	$self->_set_toolchain($toolchain);

	# Make the perl directory if it hasn't been made already.
	$self->make_path( $self->dir('perl') );

	return $toolchain;
} ## end sub _create_perl_toolchain



=head2 install_perl_* (* = git, 589, 5100, 5101, 5120, or 5121)

	$self->install_perl_5100;

The C<install_perl_*> method provides a simplified way to install
Perl into the distribution.

It takes care of calling C<install_perl_bin> with the standard
parameters.

Returns true, or throws an exception on error.

=pod

=head2 install_perl_bin

	$self->install_perl_bin(
	  name       => 'perl',
	  dist       => 'RGARCIA/perl-5.10.0.tar.gz',
	  unpack_to  => 'perl',
	  license    => {
		  'perl-5.10.0/Readme'   => 'perl/Readme',
		  'perl-5.10.0/Artistic' => 'perl/Artistic',
		  'perl-5.10.0/Copying'  => 'perl/Copying',
	  },
	  install_to => 'perl',
	);

The C<install_perl_bin> method takes care of the detailed process
of building the Perl binary and installing it into the
distribution.

A short summary of the process would be that it downloads or otherwise
fetches the named package, unpacks it, copies out any license files from
the source code, then tweaks the Win32 makefile to point to the specific
build directory, and then runs make/make test/make install. It also
registers some environment variables for addition to the installer
script.

It is normally called directly by C<install_perl_*> rather than
directly from the API, but is documented for completeness.

It takes a number of parameters that are sufficiently detailed above.

Returns true (after 20 minutes or so) or throws an exception on
error.

=cut



#####################################################################
# Perl 5.8.9 Support

sub install_perl_589 {
	my $self = shift;

	# Get the information required for Perl's toolchain.
	my $toolchain = $self->_create_perl_toolchain();

	# Install the main perl distribution.
	$self->install_perl_bin(
		url       => 'http://strawberryperl.com/package/perl-5.8.9.tar.gz',
		toolchain => $toolchain,
		patch     => [ qw{
			  lib/CPAN/Config.pm
			  win32/config.gc
			  win32/config_sh.PL
			  win32/config_H.gc
			  }
		],
		license => {
			'perl-5.8.9/Readme'   => 'perl/Readme',
			'perl-5.8.9/Artistic' => 'perl/Artistic',
			'perl-5.8.9/Copying'  => 'perl/Copying',
		},
	);

	return 1;
} ## end sub install_perl_589



sub install_perl_bin {
	my $self = shift;

	# Check for an error in the object.
	if ( not $self->bin_make() ) {
		PDWiX->throw('Cannot build Perl yet, no bin_make defined');
	}

	# Install perl.
	my $perl = Perl::Dist::WiX::Asset::Perl->new(
		parent => $self,
		@_,
	);
	$perl->install();

	# Should have a perl to use now.
	$self->_set_bin_perl( $self->file(qw/perl bin perl.exe/) );

	# Create the site/bin path so we can add it to the PATH.
	$self->make_path( catdir( $self->image_dir(), qw(perl site bin) ) );

	# Add to the environment variables
	$self->add_path( 'perl', 'site', 'bin' );
	$self->add_path( 'perl', 'bin' );

	return 1;
} ## end sub install_perl_bin



#####################################################################
# Perl 5.10.x Support

sub install_perl_5100 {
	my $self = shift;

	# Get the information required for Perl's toolchain.
	my $toolchain = $self->_create_perl_toolchain();

	# Install the main binary
	$self->install_perl_bin(
		url       => 'http://strawberryperl.com/package/perl-5.10.0.tar.gz',
		toolchain => $toolchain,
		patch     => [ qw{
			  lib/ExtUtils/Command.pm
			  lib/CPAN/Config.pm
			  win32/config.gc
			  win32/config_sh.PL
			  win32/config_H.gc
			  }
		],
		license => {
			'perl-5.10.0/Readme'   => 'perl/Readme',
			'perl-5.10.0/Artistic' => 'perl/Artistic',
			'perl-5.10.0/Copying'  => 'perl/Copying',
		},
	);

	return 1;
} ## end sub install_perl_5100



sub install_perl_5101 {
	my $self = shift;

	# Get the information required for Perl's toolchain.
	my $toolchain = $self->_create_perl_toolchain();

	# Install the main binary
	$self->install_perl_bin(
		url       => 'http://strawberryperl.com/package/perl-5.10.1.tar.gz',
		toolchain => $toolchain,
		patch     => [ qw{
			  lib/CPAN/Config.pm
			  win32/config.gc
			  win32/config_sh.PL
			  win32/config_H.gc
			  }
		],
		license => {
			'perl-5.10.1/Readme'   => 'perl/Readme',
			'perl-5.10.1/Artistic' => 'perl/Artistic',
			'perl-5.10.1/Copying'  => 'perl/Copying',
		},
	);

	return 1;
} ## end sub install_perl_5101



#####################################################################
# Perl 5.12.0 Support

sub install_perl_5120 {
	my $self = shift;

	# Get the information required for Perl's toolchain.
	my $toolchain = $self->_create_perl_toolchain();

	# Install the main binary
	$self->install_perl_bin(
		url => 'http://strawberryperl.com/package/perl-5.12.0.tar.bz2',
		toolchain => $toolchain,
		patch     => [ qw{
			  lib/CPAN/Config.pm
			  win32/config.gc
			  win32/config.gc64nox
			  win32/config_sh.PL
			  win32/config_H.gc
			  win32/config_H.gc64nox
			  }
		],
		license => {
			'perl-5.12.0/Readme'   => 'perl/Readme',
			'perl-5.12.0/Artistic' => 'perl/Artistic',
			'perl-5.12.0/Copying'  => 'perl/Copying',
		},
	);

	return 1;
} ## end sub install_perl_5120



#####################################################################
# Perl 5.12.1 Support

sub install_perl_5121 {
	my $self = shift;

	# Get the information required for Perl's toolchain.
	my $toolchain = $self->_create_perl_toolchain();

	# Install the main binary
	$self->install_perl_bin(
		url => 'http://strawberryperl.com/package/perl-5.12.1.tar.xz',
		toolchain => $toolchain,
		patch     => [ qw{
			  lib/CPAN/Config.pm
			  win32/config.gc
			  win32/config.gc64nox
			  win32/config_sh.PL
			  win32/config_H.gc
			  win32/config_H.gc64nox
			  }
		],
		license => {
			'perl-5.12.1/Readme'   => 'perl/Readme',
			'perl-5.12.1/Artistic' => 'perl/Artistic',
			'perl-5.12.1/Copying'  => 'perl/Copying',
		},
	);

	return 1;
} ## end sub install_perl_5121



#####################################################################
# Git checkout support

sub install_perl_git {
	my $self = shift;

	# Get the information required for Perl's toolchain.
	my $toolchain = $self->_create_perl_toolchain();

	# Get where the git checkout is.
	my $checkout = $self->git_checkout();

	# Install the main binary
	$self->install_perl_bin(
		url       => URI::file->new($checkout)->as_string(),
		file      => $checkout,
		toolchain => $toolchain,
		patch     => [ qw{
			  lib/CPAN/Config.pm
			  win32/config.gc
			  win32/config_sh.PL
			  win32/config_H.gc
			  }
		],
		license => {
			'perl-git/Readme'   => 'perl/Readme',
			'perl-git/Artistic' => 'perl/Artistic',
			'perl-git/Copying'  => 'perl/Copying',
		},
		git => $self->git_describe(),
	);

	return 1;
} ## end sub install_perl_git



#####################################################################
# Perl Toolchain Support

=head2 install_perl_toolchain

The C<install_perl_toolchain> method is a routine provided to install the
"perl toolchain": the modules required for CPAN (and CPANPLUS on 5.10.x 
versions of perl) to be able to install modules.

Returns true (technically, the object that called it), or throws an exception.

This is recommended to be used as a task in the tasklist, and is in 
the default tasklist after the perl interpreter is installed.

=cut

sub install_perl_toolchain {
	my $self = shift;

	# Retrieves and verifies the toolchain.
	my $toolchain = $self->_get_toolchain();
	if ( 0 == $toolchain->dist_count() ) {
		PDWiX->throw('Toolchain did not get collected');
	}

	# Install the toolchain dists
	my ( $core, $module_id );
	foreach my $dist ( $toolchain->get_dists() ) {
		my $automated_testing = 0;
		my $release_testing   = 0;
		my $overwritable      = 0;
		my $force             = $self->force();
		if ( $dist =~ /Scalar-List-Util/msx ) {

			# Does something weird with tainting
			$force = 1;
		}
		if ( $dist =~ /URI-/msx ) {

			# Can't rely on t/heuristic.t not finding a www.perl.bv
			# because some ISP's use DNS redirectors for unfindable
			# sites.
			$force = 1;
		}
		if ( $dist =~ /Time-HiRes/msx ) {

		   # Tests are so timing-sensitive they fail on their own sometimes.
			$force = 1;
		}
		if ( $dist =~ /Term-ReadLine-Perl/msx ) {

			# Does evil things when testing, and
			# so testing cannot be automated.
			$automated_testing = 1;
		}
		if ( $dist =~ /TermReadKey-2 [.] 30/msx ) {

			# Upgrading to this version, instead...
			$dist = 'STSI/TermReadKey-2.30.01.tar.gz';
		}
		if ( $dist =~ /CPAN-1 [.] 9402/msx ) {

			# 1.9402 fails its tests... ANDK says it's a test bug.
			# Alias agrees that we include 1.94_51 because of the fix
			# for the Win32 file:// bug.
			$dist  = 'ANDK/CPAN-1.94_56.tar.gz';
			$force = 1;
		}
		if ( $dist =~ /Win32API-Registry-0 [.] 31/msx ) {

			# 0.31 does not include a Makefile.PL.
			$dist = 'BLM/Win32API-Registry-0.30.tar.gz';
		}
		if ( $dist =~ /ExtUtils-MakeMaker-/msx ) {

			# There are modules that overwrite portions of this one.
			$overwritable = 1;
		}
		if ( $dist =~ /Win32API-Registry-/msx ) {

			# This module needs forced on Vista
			# (and probably 2008/Win7 as well).
			$force = 1;
		}
		if ( $dist =~ /Win32-TieRegistry-/msx ) {

			# This module needs forced on Vista
			# (and probably 2008/Win7 as well).
			$force = 1;
		}

		# Actually DO the installation, now
		# that we've got the information we need.
		$module_id = $self->_module_fix( $self->_name_to_module($dist) );
		$core =
		  exists $Module::CoreList::version{ $self->perl_version_literal() }
		  {$module_id} ? 1 : 0;
#<<<
		$self->install_distribution(
			name              => $dist,
			mod_name          => $module_id,
			force             => $force,
			automated_testing => $automated_testing,
			release_testing   => $release_testing,
			overwritable      => $overwritable,
			$self->_install_location($core),
		);
#>>>
	} ## end foreach my $dist ( $toolchain...)

	return $self;
} ## end sub install_perl_toolchain



sub _name_to_module {
	my $self = shift;
	my $dist = shift;

	# Convert a distribution name with dashes to
	# a module name with double colons.
	$self->trace_line( 3, "Trying to get module name out of $dist\n" );
#<<<
	my ( $module ) = $dist =~ m{\A  # Start the string...
					[A-Za-z/]*      # With a string of letters and slashes
					/               # followed by a forward slash. 
					(.*?)           # Then capture all characters, non-greedily 
					-\d*[.]         # up to a dash, a sequence of digits, and then a period.
					}smx;           # (i.e. starting a version number.)
#>>>
	$module =~ s{-}{::}msg;

	return $module;
} ## end sub _name_to_module

1;

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
