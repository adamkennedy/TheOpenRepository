package Oz::Script;

use 5.005;
use strict;
use Carp         'croak';
use File::Slurp  ();
use Params::Util qw{ _STRING _SCALAR };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

# Must load all of the main modules
use Oz ();





#####################################################################
# Constructor

sub new {
	my $class = shift;

	# Create the basic object
	my $self = bless {
		text => undef,
		}, $class;

	# Load the script
	my $source = shift;
	if ( _SCALAR($source) ) {
		$self->{text} = $$source;
	} elsif ( _STRING($source) ) {
		if ( $source =~ /(?:\012|\015)/ ) {
			croak("Source code should only be passed as a reference");
		}
		$self->{text} = File::Slurp::read_file( $source );
	} else {
		croak("Missing or invalid source code provided to Oz::Script->new");
	}

	$self;
}

sub text {
	$_[0]->{text};
}





#####################################################################
# Main Methods

sub write {
	my $self = shift;
	my $file = shift;
	File::Slurp::write_file( $file, $self->text );
	return 1;
}

sub run {
	my $self   = shift;
	my @params = @_;

	# Create the default compiler for this script
	my $compiler = Oz::Compiler->new(
		script => $self,
		);

	# Execute and return the result
	return $compiler->run( @params );
}

1;
