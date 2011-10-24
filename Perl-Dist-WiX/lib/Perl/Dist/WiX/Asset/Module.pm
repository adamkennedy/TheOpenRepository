package Perl::Dist::WiX::Asset::Module;

=head1 NAME

Perl::Dist::WiX::Asset::Module - Module asset for a Win32 Perl

=head1 VERSION

This document describes Perl::Dist::WiX::Asset::Module version 1.550.

=head1 SYNOPSIS

  my $distribution = Perl::Dist::WiX::Asset::Module->new(
    parent           => $dist,
    name             => 'DBI',
	force            => 0,
	assume_installed => 0,
  );
  
  $distribution->install();

=head1 DESCRIPTION

This asset installs module(s) from CPAN.

=cut

#<<<
use 5.010;
use Moose;
use WiX3::Util::StrictConstructor;
use MooseX::Types::Moose         qw( Maybe Str Bool );
use Perl::Dist::WiX::Types       qw( OneOrManyStr );
use English                      qw( -no_match_vars );
use File::Spec::Functions        qw( catdir catfile );
use File::Slurp                  qw( read_file );
use Perl::Dist::WiX::Exceptions  qw();
use File::List::Object           qw();
use IO::File                     qw();
#>>>

our $VERSION = '1.550';

with 'Perl::Dist::WiX::Role::NonURLAsset';

=pod

=head1 METHODS

This class is a L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset> 
and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::WiX::Asset::Module> object, or throws
an exception on error.

It inherits all the parameters described in the 
L<< Perl::Dist::WiX::Role::Asset->new()|Perl::Dist::WiX::Role::Asset/new >> method documentation, and adds some additional parameters.

=head3 name

The required C<name> param is the name of the module(s) to be installed.

Multiple names can be passed in, but must be passed as an arrayref.

=cut

has name => (
	is       => 'ro',
	isa      => OneOrManyStr,
	reader   => 'get_name',
	coerce   => 1,
	required => 1,
);



=head3 force

The optional boolean C<force> param allows you to specify that the tests
should be skipped and the module installed without validating its 
installation.

This can be set to true when there are test bugs that cause failing tests, 
or where true testing would be too difficult (for example, when a database
connection is required.)

This defaults to the force() attribute of the C<Perl::Dist::WiX> parent 
object.

=cut



has force => (
	is      => 'bare',
	isa     => Bool,
	reader  => '_get_force',
	lazy    => 1,
	default => sub { $_[0]->_get_parent()->force() ? 1 : 0 },
);



=head3 packlist

This tells the C<install()> routine whether the module(s) have a packlist 
that can be found once the module is installed or not.

This parameter defaults to true.

To install multiple modules, they must all have packlists.

=cut



has packlist => (
	is      => 'bare',
	isa     => Bool,
	reader  => '_get_packlist',
	default => 1,
);



=head3 assume_installed

Some distributions (Bio::Perl, for example) do not include their version 
numbers in such a way that CPAN can tell whether they are up to date after 
installation via the CPAN::Module->uptodate() call.

This parameter, when set to 1, tells Perl::Dist::WiX to skip that 
verification step.

=cut



has assume_installed => (
	is      => 'bare',
	isa     => Bool,
	reader  => '_get_assume',
	default => 0,
);



=head3 feature

Specifies which feature the module(s) are supposed to go in. 

=cut



has feature => (
	is      => 'bare',
	isa     => Maybe [Str],
	reader  => 'get_feature',
	default => undef,
);



=head2 install

The install method installs the module(s) described by the
B<Perl::Dist::WiX::Asset::Module> object and returns the files
that were installed as a L<File::List::Object|File::List::Object> object.

=cut



sub install {
	my $self = shift;

	# Set up variables needed.
	my $name          = $self->get_name();
	my $force         = $self->_get_force();
	my $assume        = $self->_get_assume();
	my $packlist_flag = $self->_get_packlist();
	my $use_sqlite    = $self->_use_sqlite();
	my $output_dir    = $self->_get_output_dir();
	my $vendor =
	    !$self->_get_parent()->portable()                    ? 1
	  : ( $self->_get_parent()->perl_major_version() >= 12 ) ? 1
	  :                                                        0;
 
	my $name_ref = $name;
	my $multiple_names = (scalar @$name > 1) ? 1 : 0;
	$name = join q{ }, @{$name_ref};
	  
	# Verify the existence of perl.
	if ( not $self->_get_bin_perl() ) {
		PDWiX->throw(
			'Cannot install CPAN modules yet, perl is not installed');
	}

	# Generate the CPAN installation script.
	my $dist_file = catfile( $self->_get_output_dir(), 'cpan_distro.txt' );
	my $url       = $self->_get_cpan()->as_string();
	my $dp_dir    = catdir( $self->_get_wix_dist_dir(), 'distroprefs' );
	my $internet_available = ( $url =~ m{ \A file://}msx ) ? 1 : 0;
	my $cpan_string        = <<"END_PERL"; # TODO: Make this a .tt?
print "Loading CPAN...\\n";
use CPAN 1.9600;
use Capture::Tiny 0.10 qw(capture_merged);
use File::Spec::Functions qw(catfile);
use File::Slurp qw(write_file);
CPAN::HandleConfig->load unless \$CPAN::Config_loaded++;
\$CPAN::Config->{'urllist'} = [ '$url' ];
\$CPAN::Config->{'use_sqlite'} = q[$use_sqlite];
\$CPAN::Config->{'prefs_dir'} = q[$dp_dir];
\$CPAN::Config->{'patches_dir'} = q[$dp_dir];
\$CPAN::Config->{'prerequisites_policy'} = q[ignore];
\$CPAN::Config->{'connect_to_internet_ok'} = q[$internet_available];
\$CPAN::Config->{'ftp'} = q[];
if ($vendor) {
	\$CPAN::Config->{'makepl_arg'} = q[INSTALLDIRS=vendor];
	\$CPAN::Config->{'make_install_arg'} = q[INSTALLDIRS=vendor];
	\$CPAN::Config->{'mbuildpl_arg'} = q[--installdirs vendor];
	\$CPAN::Config->{'mbuild_install_arg'} = q[--installdirs vendor];
}
open(\$cpan_fh, '>', '$dist_file') or die "open: \$!";
MODULE:
foreach \$name (qw($name)) {
	print "Installing \$name from CPAN...\\n";
	my \$module = CPAN::Shell->expandany( "\$name" ) 
		or die "CPAN.pm couldn't locate \$name";
	if ( \$module->uptodate() ) {
		unlink \$dist_file;
		print "\$name is up to date\\n";
		say \$cpan_fh "\$name;;;" or die "say: \$!";
		next MODULE;
	}
	print "\\\$ENV{PATH} = '\$ENV{PATH}'\\n";
	my \$output = capture_merged {
		eval {
			if ( $force ) {
				CPAN::Shell->notest('install', \$name);
			} else {
				CPAN::Shell->install(\$name);
			}
		}
	};
	my \$error = \$@;
	my \$id = \$module->distribution()->pretty_id();
	my \$time = time;
	my \$module_id = \$name;
	\$module_id =~ s{::}{_}gmsx;
	my \$filename = catfile('$output_dir', "\$time.\$module_id.output.txt");
	write_file(\$filename, \$output);
	die "Installation of \$name failed: \$error\\n" if \$error;

	say \$cpan_fh "\$name;\$id;\$filename;"  or die "say: \$!";
	print "Completed install of \$name\\n";
	unless ( $assume or \$module->uptodate() ) {
		die "Installation of \$name appears to have failed";
	}
}
close( \$cpan_fh ) or die "close: \$!";
exit(0);
END_PERL

	# Scan the perl directory if that's needed.
	my $filelist_sub;
	if ( not $self->_get_packlist() ) {
		if ($multiple_names) {
			PDWiX::Parameter->throw(
				parameter => 'packlist: Cannot be 0 when ' 
				  . 'installing multiple modules at once.',
				where => '::Asset::Module->install',
			);
		}
		$filelist_sub =
		  File::List::Object->new()->readdir( $self->_dir('perl') );
		$self->_trace_line( 5,
			    "***** Module being installed $name"
			  . " requires packlist => 0 *****\n" );
	}

	# Dump the CPAN script to a temp file and execute
	$self->_trace_line( 1, "Running install(s) of $name\n" );
	$self->_trace_line( 2, '  at ' . localtime() . "\n" );
	my $cpan_file = catfile( $self->_get_build_dir(), 'cpan_string.pl' );
  SCOPE: {
		my $CPAN_FILE;
		open $CPAN_FILE, '>', $cpan_file
		  or PDWiX->throw("CPAN script open failed: $OS_ERROR");
		print {$CPAN_FILE} $cpan_string
		  or PDWiX->throw("CPAN script print failed: $OS_ERROR");
		close $CPAN_FILE
		  or PDWiX->throw("CPAN script close failed: $OS_ERROR");
	}
	local $ENV{PERL_MM_USE_DEFAULT} = 1;
	local $ENV{AUTOMATED_TESTING}   = undef;
	local $ENV{RELEASE_TESTING}     = undef;
	$self->_run3( $self->_get_bin_perl(), $cpan_file )
	  or PDWiX->throw('CPAN script execution failed');

	if ($CHILD_ERROR) {
		PDWiX->throw(
			"Failure detected installing module(s), stopping [$CHILD_ERROR]");
	}

	# Read in cpan_distro.txt and add the distributions listed to the list of
	# distributions that were installed.
	# Also read the filelists from the modules installed.
	my (%filelists, @modules_installed);
	if ( -r $dist_file ) {
		my @dist_info;
		eval { 
			@dist_info = read_file( $dist_file );
			1;
		} || PDWiX->throw("CPAN modules file error: $EVAL_ERROR");

		# Start processing through the distributions that were installed.
		foreach my $dist_info_line (@dist_info) {
			my ($module_name, $dist_installed, $output_file) = split ';', $dist_info_line;
			if ( q{} eq $dist_installed ) {
				$self->_trace_line( 0,
					"Module $module_name was up-to-date\n" );
			} else {
				$self->_add_to_distributions_installed($dist_installed);
				push @modules_installed, $module_name;
				if ($packlist_flag) {
					# The filelist is filtered during _search_packlist.
					my $filelist = $self->_search_packlist($module_name, $output_file, $dist_installed);					
					$filelists{$module_name} = $filelist;
				} elsif (1 < scalar @dist_info) {
					# Can't pass in 0 to packlist and install more than 1 module.
					PDWiX::Parameter->throw(
						parameter => 'packlist: Cannot be 0 when ' 
						  . 'installing multiple modules at once.',
						where => '::Asset::Module->install',
					);
				} else {
					my $filelist =
					  File::List::Object->new()->readdir( $self->_dir('perl') );
					$filelist->subtract($filelist_sub)->filter( $self->_filters() );
					$filelists{$module_name} = $filelist;
				}
			}
		}
	} else {
		$self->_trace_line( 0,
			"All module(s) $name were up-to-date\n" );
	}

	# Returns the filelists.
	return \%filelists;
} ## end sub install

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<Perl::Dist::WiX::Role::Asset|Perl::Dist::WiX::Role::Asset>

=head1 COPYRIGHT

Copyright 2009 - 2011 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
