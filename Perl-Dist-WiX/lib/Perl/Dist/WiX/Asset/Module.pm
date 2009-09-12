package Perl::Dist::WiX::Asset::Module;

use Moose;
use MooseX::Types::Moose qw( Str Bool ); 
use English qw( -no_match_vars ); 
use File::Spec::Functions qw( catdir catfile );
require Perl::Dist::WiX::Exceptions;
require File::List::Object;
require IO::File;

our $VERSION = '1.090_102';
$VERSION = eval $VERSION;

with 'Perl::Dist::WiX::Role::NonURLAsset';

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_name',
	required => 1,
);

has force => (
	is       => 'ro',
	isa      => Bool,
	reader   => '_get_force',
	lazy     => 1,
	default  => sub { $_[0]->_get_parent()->force() ? 1 : 0 },
);

has packlist => (
	is       => 'ro',
	isa      => Bool,
	reader   => '_get_packlist',
	default  => 1,
);

# Don't know what these are for. TODO: Delete.
#use Object::Tiny qw{
#	type
#	extras
#};

sub install {
	my $self   = shift;
	my $name  = $self->get_name();
	my $force = $self->_get_force();
		
	my $packlist_flag = $self->_get_packlist();

	unless ( $self->_get_bin_perl ) {
		PDWiX->throw(
			'Cannot install CPAN modules yet, perl is not installed');
	}
	my $dist_file = catfile( $self->_get_output_dir, 'cpan_distro.txt' );

	# Generate the CPAN installation script.
	# Fix url's for minicpans until 1.9403 is released.
	my $url = $self->_get_cpan()->as_string();
	$url =~ s{\Afile:///C:/}{file://C:/}msx;

	my $dp_dir = catdir( $self->_get_wix_dist_dir, 'distroprefs' );
	my $internet_available = ($url =~ m{ \A file://}msx) ? 1 : 0; 
	
	my $cpan_string = <<"END_PERL";
print "Loading CPAN...\\n";
use CPAN;
CPAN::HandleConfig->load unless \$CPAN::Config_loaded++;
\$CPAN::Config->{'urllist'} = [ '$url' ];
\$CPAN::Config->{'use_sqlite'} = q[0];
\$CPAN::Config->{'prefs_dir'} = q[$dp_dir];
\$CPAN::Config->{'prerequisites_policy'} = q[ignore];
\$CPAN::Config->{'connect_to_internet_ok'} = q[$internet_available];
\$CPAN::Config->{'ftp'} = q[];
\$CPAN::Config->{'makepl_arg'} = q[INSTALLDIRS=vendor];
\$CPAN::Config->{'make_install_arg'} = q[INSTALLDIRS=vendor];
\$CPAN::Config->{'mbuildpl_arg'} = q[--installdirs vendor];
\$CPAN::Config->{'mbuild_install_arg'} = q[--installdirs vendor];
print "Installing $name from CPAN...\\n";
my \$module = CPAN::Shell->expandany( "$name" ) 
	or die "CPAN.pm couldn't locate $name";
my \$dist_file = '$dist_file'; 
if ( \$module->uptodate ) {
	unlink \$dist_file;
	print "$name is up to date\\n";
	exit(0);
}
SCOPE: {
	open( CPAN_FILE, '>', \$dist_file )      or die "open: $!";
	print CPAN_FILE 
		\$module->distribution()->pretty_id() or die "print: $!";
	close( CPAN_FILE )                       or die "close: $!";
}

print "\\\$ENV{PATH} = '\$ENV{PATH}'\\n";
if ( $force ) {
	CPAN::Shell->notest('install', '$name');
} else {
	CPAN::Shell->install('$name');
}
print "Completed install of $name\\n";
unless ( \$module->uptodate ) {
	die "Installation of $name appears to have failed";
}
exit(0);
END_PERL

	my $filelist_sub;
	if ( not $self->_get_packlist() ) {
		$filelist_sub = File::List::Object->new->readdir(
			catdir( $self->image_dir, 'perl' ) );
		$self->_trace_line( 5,
			    "***** Module being installed $name"
			  . " requires packlist => 0 *****\n" );
	}

	# Dump the CPAN script to a temp file and execute
	$self->_trace_line( 1, "Running install of $name\n" );
	$self->_trace_line( 2, '  at ' . localtime() . "\n" );
	my $cpan_file = catfile( $self->_get_build_dir(), 'cpan_string.pl' );
  SCOPE: {
		my $CPAN_FILE;
		open $CPAN_FILE, '>', $cpan_file
		  or PDWiX->throw("CPAN script open failed: $!");
		print {$CPAN_FILE} $cpan_string
		  or PDWiX->throw("CPAN script print failed: $!");
		close $CPAN_FILE or PDWiX->throw("CPAN script close failed: $!");
	}
	local $ENV{PERL_MM_USE_DEFAULT} = 1;
	local $ENV{AUTOMATED_TESTING}   = undef;
	local $ENV{RELEASE_TESTING}     = undef;
	$self->_run3( $self->_get_bin_perl, $cpan_file )
	  or PDWiX->throw('CPAN script execution failed');
	PDWiX->throw(
		"Failure detected installing $name, stopping [$CHILD_ERROR]")
	  if $CHILD_ERROR;

	# Read in the dist file and return it as $dist_info.
	my @files;
	if ( -r $dist_file ) {
		my $fh = IO::File->new( $dist_file, 'r' );
		if ( not defined $fh ) {
			PDWiX->throw("CPAN modules file error: $!");
		}
		my $dist_info = <$fh>;
		$fh->close;
		$dist_info =~ s{\.tar\.gz}{}msx;   # Take off extensions.
		$dist_info =~ s{\.zip}{}msx;
		$dist_info =~ s{.+\/}{}msx;    # Take off directories.
		$self->_add_to_distributions_installed($dist_info);
	} else {
		$self->_trace_line( 0,
			"Distribution for module $name was up-to-date\n" );
	}

	# Making final filelist.
	my $filelist;
	if ($packlist_flag) {
		$filelist = $self->_search_packlist( $name );
	} else {
		$filelist = File::List::Object->new()->readdir(
			catdir( $self->image_dir, 'perl' ) );
		$filelist->subtract($filelist_sub)->filter( $self->_filters );
	}

	return $filelist;
} ## end sub install_module

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::Asset::Module - Module asset for a Win32 Perl

=head1 SYNOPSIS

  my $distribution = Perl::Dist::WiX::Asset::Module->new(
    ...
  );

=head1 DESCRIPTION

TODO

=head1 METHODS

TODO

This class is a L<Perl::Dist::WiX::Role::Asset> and shares its API.

=head2 new

The C<new> constructor takes a series of parameters, validates then
and returns a new B<Perl::Dist::WiX::Asset::Distribution> object.

It inherits all the params described in the L<Perl::Dist::WiX::Role::Asset> 
C<new> method documentation, and adds some additional params.

=over 4

=item name

The required C<name> param is the name of the package for the purposes
of identification.

This should match the name of the Perl distribution without any version
numbers. For example, "File-Spec" or "libwww-perl".

Alternatively, the C<name> param can be a CPAN path to the distribution
such as shown in the synopsis.

In this case, the url to fetch from will be derived from the name.

=item force

Unlike in the CPAN client installation, in which all modules MUST pass
their tests to be added, the secondary method allows for cases where
it is known that the tests can be safely "forced".

The optional boolean C<force> param allows you to specify that the tests
should be skipped and the module installed without validating it.

=item automated_testing

Many modules contain additional long-running tests, tests that require
additional dependencies, or have differing behaviour when installing
in a non-user automated environment.

The optional C<automated_testing> param lets you specify that the
module should be installed with the B<AUTOMATED_TESTING> environment
variable set to true, to make the distribution behave properly in an
automated environment (in cases where it doesn't otherwise).

=item release_testing

Some modules contain release-time only tests, that require even heavier
additional dependencies compared to even the C<automated_testing> tests.

The optional C<release_testing> param lets you specify that the module
tests should be run with the additional C<RELEASE_TESTING> environment
flag set.

By default, C<release_testing> is set to false to squelch any accidental
execution of release tests when L<Perl::Dist::WiX> itself is being tested
under C<RELEASE_TESTING>.

=item makefilepl_param

Some distributions illegally require you to pass additional non-standard
parameters when you invoke "perl Makefile.PL".

The optional C<makefilepl_param> param should be a reference to an ARRAY
where each element contains the argument to pass to the Makefile.PL.

=item buildpl_param

Some distributions require you to pass additional non-standard
parameters when you invoke "perl Build.PL".

The optional C<buildpl_param> param should be a reference to an ARRAY
where each element contains the argument to pass to the Build.PL.

=back

The C<new> method returns a B<Perl::Dist::WiX::Asset::Distribution> object,
or throws an exception on error.

=head2 install

The install method installs the website link described by the
B<Perl::Dist::WiX::Asset::Website> object and returns a file
that was installed as a L<File::List::Object> object.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX>, L<Perl::Dist::WiX::Role::Asset>

=head1 COPYRIGHT

Copyright 2009 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
