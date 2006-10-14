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

=cut

use 5.005;
use strict;
use Carp           ('croak');
use File::Spec     ();
use File::Basename ();
use Params::Util   ('_STRING', '_CLASS');

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Precalculate the absolute basedir
	$self->{pip} = File::Spec->rel2abs( $self->pip );
	$self->{dir} = File::Basename::dirname( $self->pip );

	return $self;
}

sub read {
	my $class = shift;

	# Check the file
	my $pip = shift or croak( 'You did not specify a file name' );
	croak( "File '$pip' does not exist" )              unless -e $pip;
	croak( "'$pip' is a directory, not a file" )       unless -f _;
	croak( "Insufficient permissions to read '$pip'" ) unless -r _;

	# Slurp in the file
	SCOPE: {
		local $/ = undef;
		open CFG, $pip or croak( "Failed to open file '$pip': $!" );
		my $contents = <CFG>;
		close CFG;
	}

	# Split and find the header line for the type
	my @lines  = split /(?:\015{1,2}\012|\015|\012)/, $contents;
	my $header = shift @lines;
	unless ( _CLASS($header) ) {
		croak("Invalid header '$header', not a class name");
	}

	# Load the class
	require join('/', split /::/, $header);
	unless ( $header->VERSION and $header->isa($class) ) {
		croak("Invalid header '$header', class is not a Module::Plan::Base subclass");
	}

	# Class looks good, create our object and hand off
	return $header->new(
		pip   => $pip,
		lines => \@lines,
		names => [ ],
		dists => { },
		);
}

sub pip {
	$_[0]->{pip};
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





#####################################################################
# Files and Installation

sub add_file {
	my $self = shift;
	my $file = _STRING(shift) or croak("Did not provide a file name");

	# Handle relative and absolute paths
	$file = File::Spec->rel2abs( $file );
	(undef, undef, $name) = File::Spec->splitpath( $file );

	# Add the name and the file name
	push @{ $self->{names} }, $name;
	$self->{dists}->{$name} = $file;
}

1;
