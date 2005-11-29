package PITA::Report::Parser;

=pod

=head1 NAME

PITA::Report::Parser - Implements a 

=cut

use strict;
use base 'XML::SAX::Base';
use Carp         'croak';
use Params::Util ':ALL';

use vars qw{$VERSION $XML_NAMESPACE %TRIM};
BEGIN {
	$VERSION = '0.01';

	# Define the XML namespace we are a parser for
	$XML_NAMESPACE = 'http://ali.as/xml/schemas/PITA/1.0';

	# The list of tags to trim character whitespace for
	%TRIM = map { $_ => 1 } qw{
		osname    archname
		distname  filename  md5sum  cpanpath
		};
}






#####################################################################
# Constructor

sub new {
	my $class  = shift;
	my $parent = _INSTANCE(shift, 'PITA::Report')
		or croak("Did not provie a PITA::Report param");

	# Create the basic parsing object
	my $self = bless {
		parent => $parent,
		}, $class;

	$self;
}





#####################################################################
# Simplification Layer

sub start_element {
	my ($self, $element) = @_;

	# We don't support namespaces.
	if ( $element->{Prefix} ) {
		croak( __PACKAGE__ . ' does not support XML namespaces' );
	}

	# Flatten the Attributes into a simple hash
	my %hash = map { $_->{LocalName}, $_->{Value} }
		grep { $_->{Value} =~ s/^\s+//; $_->{Value} =~ s/\s+$//; 1; }
		grep { ! $_->{Prefix} }
		values %{$element->{Attributes}};

	# Handle off to the appropriate tag-specific handler
	my $handler = "start_element_$element->{LocalName}";
	$self->can($handler)
		? $self->$handler( \%hash )
		: croak("No handler for tag $element->{LocalName}");
}

sub end_element {
	my ($self, $element) = @_;

	# Hand off to the optional tag-specific handler
	my $handler = "end_element_$element->{LocalName}";
	if ( $self->can($handler) ) {
		# If there is anything in the character buffer, trim whitespace
		if ( defined $self->{character_buffer} ) {
			$self->{character_buffer} =~ s/^\s+//;
			$self->{character_buffer} =~ s/\s+$//;
		}

		$self->$handler();
	}

	# Clean up
	delete $self->{character_buffer};

	1;
}

# Because we don't know in what context this will be called,
# we just store all character data in a character buffer
# and deal with it in the various end_element methods.
sub characters {
	my ($self, $element) = @_;

	# Add to the buffer
	$self->{character_buffer} .= $element->{Data};

	1;
}

# Generate the methods for the simple properties
BEGIN {
	foreach my $element ( qw{
		osname   archname perlv
		distname filename md5sum cpanpath
	} ) {
		eval <<"END_PERL";
sub start_element_$element {
	1;
}

sub end_element_$element {
	my \$self = shift;
	\$self->{context}->[-1]->{$element} = \$self->{character_buffer};
	1;
}
END_PERL

	}
}





#####################################################################
# Simplified Tag-Specific Event Handlers
# The simplified event handlers are passed arguments in the forms
# start_element_foo( $self, \%attribute_hash )
# end_element_foo  ( $self )

sub start_element_distribution {
	my ($self, $hash) = @_;

	# Create a new ::Distribution object and add to the context
	my $distribution = bless {}, 'PITA::Report::Distribution';
	push @{$self->{context}}, $distribution;

	1;
}

sub end_element_distribution {
	my $self = shift;

	# Take the distribution off the end of the context
	my $distribution = pop @{$self->{context}};

	# Complete it and add to the larger $FOO
	$distribution->_init;
	die "CODE INCOMPLETE";
}

sub start_element_filename {
	my ($self, $hash) = @_;
	1;
}

sub end_element_filename {
	my $self = shift;
	$self->{context}->[-1]->{filename} = $self->{character_buffer};
	1;
}

1;
