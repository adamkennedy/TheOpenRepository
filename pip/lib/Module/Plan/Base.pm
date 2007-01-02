package Module::Plan::Base;

=pod

=head1 NAME

Module::Plan::Base - Base class for Module::Plan classes

=head1 DESCRIPTION

B<Module::Plan::Base> provides the underlying basic functionality. That is,
taking a file, injecting it into CPAN, and the installing it via the L<CPAN>
module.

It also provides for a basic "phase" system, that allows steps to be taken
in the appropriate order. This is very simple for now, but may be upgraded
later into a dependency-based system.

This class is undocumented for the moment.

See L<pip> for the front-end console application for this module.

=cut

use 5.005;
use strict;
use Carp           ('croak');
use File::Spec     ();
use File::Temp     ();
use File::Basename ();
use Params::Util   ('_STRING', '_CLASS', '_INSTANCE');
use URI            ();
use LWP::Simple    ();
use CPAN::Inject   ();
use CPAN;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.07';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Create internal state variables
	$self->{names}     = [ ];
	$self->{uris}      = { };
	$self->{dists}     = { };
	$self->{cpan_path} = { };

	# Precalculate the various paths for the P5I file
	$self->{p5i_uri}   = $self->_p5i_uri( $self->p5i     );
	$self->{p5i_dir}   = $self->_p5i_dir( $self->p5i_uri );
	$self->{dir}       = File::Temp::tempdir( CLEANUP => 1 );

	# Create the CPAN injector
	$self->{inject} ||= CPAN::Inject->from_cpan_config;
	unless ( _INSTANCE($self->{inject}, 'CPAN::Inject') ) {
		Carp::croak("Did not provide a valid 'param' CPAN::Inject object");
	}

	$self;
}

sub read {
	my $class = shift;

	# Check the file
	my $p5i = shift or croak( 'You did not specify a file name' );
	croak( "File '$p5i' does not exist" )              unless -e $p5i;
	croak( "'$p5i' is a directory, not a file" )       unless -f _;
	croak( "Insufficient permissions to read '$p5i'" ) unless -r _;

	# Slurp in the file
	my $contents;
	SCOPE: {
		local $/ = undef;
		open CFG, $p5i or croak( "Failed to open file '$p5i': $!" );
		$contents = <CFG>;
		close CFG;
	}

	# Split and find the header line for the type
	my @lines  = split /(?:\015{1,2}\012|\015|\012)/, $contents;
	my $header = shift @lines;
	unless ( _CLASS($header) ) {
		croak("Invalid header '$header', not a class name");
	}

	# Load the class
	require join('/', split /::/, $header) . '.pm';
	unless ( $header->VERSION and $header->isa($class) ) {
		croak("Invalid header '$header', class is not a Module::Plan::Base subclass");
	}

	# Class looks good, create our object and hand off
	return $header->new(
		p5i   => $p5i,
		lines => \@lines,
		);
}

sub p5i {
	$_[0]->{p5i};
}

sub p5i_uri {
	$_[0]->{p5i_uri};
}

sub p5i_dir {
	$_[0]->{p5i_dir};
}

sub dir {
	$_[0]->{dir};
}

sub lines {
	@{ $_[0]->{lines} };
}

sub names {
	@{ $_[0]->{names} };
}

sub dists {
	%{ $_[0]->{dists} };
}

sub uris {
	my $self = shift;
	my %copy = %{ $self->{uris} };
	foreach my $key ( keys %copy ) {
		$copy{$key} = $copy{$key}->clone;
	}
	%copy;
}

sub inject {
	$_[0]->{inject};
}





#####################################################################
# Files and Installation

sub add_file {
	my $self = shift;
	my $file = _STRING(shift) or croak("Did not provide a file name");

	# Handle relative and absolute paths
	$file = File::Spec->rel2abs( $file, $self->dir );
	my (undef, undef, $name) = File::Spec->splitpath( $file );

	# Check for duplicates
	if ( scalar grep { $name eq $_ } @{$self->{names}} ) {
		croak("Duplicate file $name in plan");
	}

	# Add the name and the file name
	push @{ $self->{names} }, $name;
	$self->{dists}->{$name} = $file;

	return 1;
}

sub add_uri {
	my $self = shift;
	my $uri  = _INSTANCE(shift, 'URI') or croak("Did not provide a URI");
	unless ( $uri->can('path') ) {
		croak("URI is not have a ->path method");
	}

	# Split into segments to get the file
	my @segments = $uri->path_segments;
	my $name     = $segments[-1];

	# Check for duplicates
	if ( scalar grep { $name eq $_ } @{$self->{names}} ) {
		croak("Duplicate file $name in plan");
	}

	# Add the name and the file name
	push @{ $self->{names} }, $name;
	$self->{uris}->{$name} = $uri;

	return 1;
}

sub run {
	die ref($_[0]) . " does not implement 'run'";
}

sub _fetch_uri {
	my $self = shift;
	my $name = shift;
	my $uri  = $self->{uris}->{$name};
	unless ( $uri ) {
		die("Unknown uri for $name");
	}

	# Determine the dists file name
 	my $file = File::Spec->catfile( $self->{dir}, $name );
	if ( -f $file ) {
		die("File $file already exists");
	}
	$self->{dists}->{$name} = $file;

	# Download the URI to the destination
	my $content = LWP::Simple::get( $uri );
	unless ( defined $content ) {
		croak("Failed to download $uri");
	}

	# Save the file
	unless ( open( DOWNLOAD, '>', $file ) ) {
		croak("Failed to open $file to write");
	}
	binmode( DOWNLOAD );
	unless ( print DOWNLOAD $content ) {
		croak("Failed to write to $file");
	}
	unless ( close( DOWNLOAD ) ) {
		croak("Failed to close $file");
	}

	return 1;
}

sub _cpan_inject {
	my $self = shift;
	my $name = shift;
	my $file = $self->{dists}->{$name};
	unless ( $file ) {
		die("Unknown file $name");
	}

	# Inject the file into the CPAN cache
	$self->{cpan_path}->{$name} = $self->inject->add( file => $file );

	1;
}

sub _cpan_install {
	my $self   = shift;
	my $name   = shift;
	my $distro = $self->{cpan_path}->{$name};
	unless ( $distro ) {
		die("Unknown file $name");
	}

	# Install via the CPAN::Shell
	CPAN::Shell->install($distro);
}

# Takes arbitrary param, returns URI to the P5I file
sub _p5i_uri {
	my $uri = _INSTANCE($_[1], 'URI') ? $_[1]
		: _STRING($_[1])          ? URI->new($_[1])
		: undef
		or croak("Not a valid P5I path");

	# Convert generics to file URIs
	unless ( $uri->scheme ) {
		# It's a raw filename
		$uri = URI->new("file:$uri") or croak("Not a valid P5I path");
	}

	# Make any file paths absolute
	if ( $uri->isa('URI::file') ) {
		my $file = File::Spec->rel2abs( $uri->path );
		$uri = URI->new( "file:$file" );
	}

	$uri;
}

sub _p5i_dir {
	my $uri = _INSTANCE($_[1], 'URI')
		or croak("Did not pass a URI to p5i_dir");

	# Use a naive method for the moment
	my $string = $uri->as_string;
	$string =~ s/\/[^\/]+$//;

	# Return the modified version
	URI->new( $string, $uri->scheme );
}

1;

=pod

=head1 SUPPORT

This module is stored in an Open Repository at the following address.

L<http://svn.phase-n.com/svn/cpan/trunk/Module-Plan-Base>

Write access to the repository is made available automatically to any
published CPAN author, and to most other volunteers on request.

If you are able to submit your bug report in the form of new (failing)
unit tests, or can apply your fix directly instead of submitting a patch,
you are B<strongly> encouraged to do so. The author currently maintains
over 100 modules and it may take some time to deal with non-Critical bug
reports or patches.

This will guarentee that your issue will be addressed in the next
release of the module.

If you cannot provide a direct test or fix, or don't have time to do so,
then regular bug reports are still accepted and appreciated via the CPAN
bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Plan-Base>

For other issues, for commercial enhancement and support, or to have your
write access enabled for the repository, contact the author at the email
address above.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<pip>, L<Module::Plan>, L<Module::Inspector>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
