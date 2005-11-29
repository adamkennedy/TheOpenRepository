package PITA::Report::SAXParser;

=pod

=head1 NAME

PITA::Report::SAXParser - Implements a SAX Parser for PITA::Report files

=head1 DESCRIPTION

Although you won't need to use it directly, this class provides a
"SAX Parser" class that converts a stream of SAX events (most likely from
an XML file) and populates a L<PITA::Report> with L<PITA::Report::Install>
objects.

Please note that this class is incomplete at this time. Although you
can create objects and parse some of the tags, many are still ignored
at this time (in particular the E<lt>outputE<gt> and E<lt>analysisE<gt>
tags.

=head1 METHODS

In addition to the following documented methods, this class implements
a large number of methods relating to its implementation of a
L<XML::SAX::Base> subclass. These are not considered part of the
public API, and so are not documented here.

=cut

use strict;
use base 'XML::SAX::Base';
use Carp         'croak';
use Params::Util ':ALL';

use vars qw{$VERSION $XML_NAMESPACE %TRIM};
BEGIN {
	$VERSION = '0.01_01';

	# Define the XML namespace we are a parser for
	$XML_NAMESPACE = 'http://ali.as/xml/schemas/PITA/1.0';

	# The list of tags to trim character whitespace for
	%TRIM = map { $_ => 1 } qw{
		osname    archname  perlpath
		distname  filename  cpanpath  md5sum  
		};
}






#####################################################################
# Constructor

=pod

=head2 new

  # Create the SAX parser
  my $parser = PITA::Report::SAXParser->new( $report );

The C<new> constructor takes a single L<PITA::Report> object and creates
a SAX Parser for it. When used, the SAX Parser object will fill the empty
L<PITA::Report> object with L<PITA::Report::Install> reporting objects.

If used with a L<PITA::Report> that already has existing content, it
will add the new install reports in addition to the existing ones.

Returns a new C<PITA::Report::SAXParser> object, or dies on error.

=cut

sub new {
	my $class  = shift;
	my $report = _INSTANCE(shift, 'PITA::Report')
		or croak("Did not provie a PITA::Report param");

	# Create the basic parsing object
	my $self = bless {
		report => $report,
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

	# Shortcut if we don't implement a handler
	my $handler = "start_element_$element->{LocalName}";
	return 1 unless $self->can($handler);

	# Flatten the Attributes into a simple hash
	my %hash = map { $_->{LocalName}, $_->{Value} }
		grep { $_->{Value} =~ s/^\s+//; $_->{Value} =~ s/\s+$//; 1; }
		grep { ! $_->{Prefix} }
		values %{$element->{Attributes}};

	# Hand off to the handler
	$self->$handler( \%hash );
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
		osname    archname  perlpath  perlv
		distname  filename  cpanpath  md5sum   
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

### Ignore the actual report tag
# sub start_element_report {}
# sub end_element_report {}





#####################################################################
# Handle the <install>...</install> tag

sub start_element_install {
	my ($self, $hash) = @_;

	# Create a new ::Install object and add to the context
	my $install = bless {}, 'PITA::Report::Install';
	push @{$self->{context}}, $install;

	1;
}

sub end_element_install {
	my $self = shift;

	# Take the install off the end of the context
	my $install = pop @{$self->{context}};

	# Complete it and add to the larger $FOO
	$install->_init;

	# Add it to the report
	$self->{report}->add_install( $install );

	1;
}





#####################################################################
# Handle the <distribution>...</distribution> tag

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

	# Set it in the install object
	$self->{context}->[-1]->{distribution} = $distribution;

	1;
}





#####################################################################
# Handle the <platform>...</platform> tag

sub start_element_platform {
	my ($self, $hash) = @_;

	# Create a new ::Distribution object and add to the context
	my $platform = bless {}, 'PITA::Report::Platform';
	push @{$self->{context}}, $platform;

	1;
}

sub end_element_platform {
	my $self = shift;

	# Take the distribution off the end of the context
	my $platform = pop @{$self->{context}};

	# Complete it and add to the larger $FOO
	$platform->_init;

	# Set it in the install object
	$self->{context}->[-1]->{platform} = $platform;

	1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-Report>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 SEE ALSO

L<PITA::Report>, L<PITA::Report::SAXDriver>

The Perl Image-based Testing Architecture (L<http://ali.as/pita/>)

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
