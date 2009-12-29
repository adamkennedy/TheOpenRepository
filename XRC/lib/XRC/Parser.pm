package XRC::Parser;

use 5.008;
use strict;
use warnings;
use Params::Util   qw{ _CLASS _INSTANCE };
use XML::SAX::Base ();
use XRC            ();

our $VERSION = '0.01';
our @ISA     = 'XML::SAX::Base';

use constant NAMESPACE => 'http://www.wxwindows.org/wxxrc';





######################################################################
# Constructor and Accessors

sub new {
	my $class  = _CLASS(shift);
	my $parent = _INSTANCE(shift, 'XRC');

	# Create the basic parsing object
	my $self = bless {
		stack => [ $parent ],
	}, $class;

	$self;
}

sub parent {
	$_[0]->{stack}->[-1];
}





######################################################################
# Generic SAX Handlers

sub start_element {
	my ($self, $element) = @_;

	# We don't support namespaces
	if ( $element->{Prefix} ) {
		die(__PACKAGE__ . ' does not support XML namespaces');
	}

	# Flatten the Attributes into a simple hash
	my %hash = map { $_->{LocalName}, $_->{Value} }
		grep { $_->{Value} =~ s/^\s+//; $_->{Value} =~ s/\s+$//; 1; }
		grep { ! $_->{Prefix} }
		values %{$element->{Attributes}};

	# Handle off to the appropriate tag-specific handler
	my $handler = "start_element_$element->{LocalName}";
	unless ( $self->can($handler) ) {
		die("No handler for tag $element->{LocalName}");
	}

	return $self->$handler( \%hash );
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
	# Add to the buffer
	$_[0]->{character_buffer} .= $_[1]->{Data};
}





######################################################################
# Simple Tag Handlers

eval <<"END_PERL" foreach qw{ title orient };
sub start_element_$_ {
	\$_[0]->{character_buffer} = '';
}

sub end_element_$_ {
	\$_[0]->parent->$_( \$_[0]->{character_buffer} );
}
END_PERL





######################################################################
# Tag-Specific SAX Handlers

# <resource>
# Top level contain, appears to serve no useful purpose.
# So lets just set the container context to be the root.
# This can just be ignored.
sub start_element_resource {
	return 1;
}

sub end_element_resource {
	return 1;
}

# Object XML class to Perl class mapping
my %OBJECT_CLASS = (
	wxDialog   => 'XRC::Dialog',
	wxBoxSizer => 'XRC::BoxSizer',
);

# <object>
# Primary tag for useful elements in a GUI, such as windows and buttons.
sub start_element_object {
	my $self = shift;
	my $attr = shift;

	# Identify the type of object to create
	my $class = delete $attr->{class};
	unless ( $OBJECT_CLASS{$class} ) {
		die("Unknown or unsupported object class '$class'");
	}

	# Create the object
	push @{$self->{stack}}, $OBJECT_CLASS{$class}->new(%$attr);
}

sub end_element_object {
	my $self   = shift;
	my $object = pop @{$self->{stack}};
	$self->parent->add_object( $object );
}

# <style>
# Pipe-separated list of style constants to apply to the object
sub start_element_style {
	$_[0]->{character_buffer} = '';
}

sub end_element_style {
	my $self  = shift;
	my @style = split /\|/, $self->{character_buffer};
	$self->parent->style( \@style );
}

# <size>
# An X/Y height and width pair
sub start_element_size {
	$_[0]->{character_buffer} = '';
}

sub end_element_size {
	my $self = shift;
	my @part = split /,/, $self->{character_buffer};
	my $size = XRC::Size->new(
		width  => $part[0],
		height => $part[1],
	);
	$self->parent->size( $size );
}

1;
