package FBP::Parser;

use 5.008;
use strict;
use warnings;
use Params::Util   qw{ _CLASS _INSTANCE };
use XML::SAX::Base ();
use FBP            ();

our $VERSION = '0.02';
our @ISA     = 'XML::SAX::Base';





######################################################################
# Constructor and Accessors

sub new {
	my $class  = _CLASS(shift);
	my $parent = _INSTANCE(shift, 'FBP');
	unless ( $parent ) {
		die("Did not provide a parent FBP object");
	}

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
	my $handler = 'start_element_' . lc $element->{LocalName};
	unless ( $self->can($handler) ) {
		die("No handler for tag $element->{LocalName}");
	}

	return $self->$handler( \%hash );
}

sub end_element {
	my ($self, $element) = @_;

	# Hand off to the optional tag-specific handler
	my $handler = 'end_element_' . lc $element->{LocalName};
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
# Tag-Specific SAX Handlers

# <wxFormBuilder_Project>
# Top level contain, appears to serve no useful purpose.
# So lets just set the container context to be the root.
# This can just be ignored.
sub start_element_wxformbuilder_project {
	return 1;
}

sub end_element_wxformbuilder_project {
	return 1;
}

# <FileVersion>
# Ignore the file version for now.
sub start_element_fileversion {
	return 1;
}

sub end_element_fileversion {
	return 1;
}

# Object XML class to Perl class mapping
my %OBJECT_CLASS = (
	Project      => 'FBP::Project',
	Dialog       => 'FBP::Dialog',
	wxBoxSizer   => 'FBP::BoxSizer',
	wxButton     => 'FBP::Button',
	wxStaticText => 'FBP::StaticText',
	wxStaticLine => 'FBP::StaticLine',
	sizeritem    => 'FBP::SizerItem',
);

# <object>
# Primary tag for useful elements in a GUI, such as windows and buttons.
sub start_element_object {
	my $self = shift;
	my $attr = shift;

	# Identify the type of object to create
	unless ( $OBJECT_CLASS{$attr->{class}} ) {
		die("Unknown or unsupported object class '$attr->{class}'");
	}

	# Store the raw hash until the closing tag
	$attr->{class} = $OBJECT_CLASS{$attr->{class}};
	push @{$self->{stack}}, $attr;
}

sub end_element_object {
	my $self     = shift;
	my $attr     = pop @{$self->{stack}};
	my $class    = delete $attr->{class};
	my $children = delete $attr->{children};
	my $object   = $class->new(
		%$attr,
		raw => $attr,
		$children ? ( children => $children ) : ( )
	);
	$self->parent->{children} ||= [ ];
	push @{$self->parent->{children}}, $object;
}

# <property>
# Primary tag for attributes of objects
sub start_element_property {
	my $self = shift;
	my $attr = shift;

	# Add a naked atribute hash to the stack
	$self->{character_buffer} = '';
	push @{$self->{stack}}, $attr->{name};
}

sub end_element_property {
	my $self  = shift;
	my $name  = pop @{$self->{stack}};
	my $value = $self->{character_buffer};
	$self->parent->{$name} = $value;
}

# <event>
# Primary tag for events bound to objects
sub start_element_event {
	my $self = shift;
	my $attr = shift;

	# Add a naked atribute hash to the stack
	$self->{character_buffer} = '';
	push @{$self->{stack}}, $attr->{name};
}

sub end_element_event {
	my $self  = shift;
	my $name  = pop @{$self->{stack}};
	my $value = $self->{character_buffer};
	$self->parent->{$name} = $value if length $value;
}

1;
