package PITA::Report;

=pod

=head1 NAME

PITA::Report - Create, load, save and manipulate XML PITA reports

=head1 SYNOPSIS

=cut

use strict;
use Carp                       'croak';
use Params::Util               ':ALL';
use IO::File                   ();
use File::Flock                ();
use XML::SAX::ParserFactory    ();
use XML::Validator::Schema     ();
use PITA::Report::Platform     ();
use PITA::Report::Distribution ();
use PITA::Report::Install      ();
use PITA::Report::SAXParser    ();
use PITA::Report::SAXDriver    ();

use vars qw{$VERSION $SCHEMA};
BEGIN {
	$VERSION = '0.01';
}

# Locate the Schema
$SCHEMA = $INC{'PITA/Report.pm'};
$SCHEMA =~ s/pm$/xsd/;
unless ( -f $SCHEMA and -r _ ) {
	Carp::croak("Cannot locate XML Schema. PITA::Report load failed");
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;

	# No params creates a new empty object
	my $self = bless {
		installs => {},
		}, $class;
	return $self unless @_;

	# Validate the document
	my $fh = $self->_file(shift);
	$self->validate( $fh );

	# Build the object from the file
	my $parser = XML::SAX::ParserFactory->parser(
		Handler => PITA::Report::SAXParser->new( $self ),
		);
        $parser->parse_file($fh);

	$self;
}

# Validate the report
sub validate {
	my $class = shift;
	my $fh    = $class->_file(shift);

	# Create the validator
	my $parser = XML::SAX::ParserFactory->parser(
		Handler => XML::Validator::Schema->new(file => $SCHEMA),
		);

	# Validate the document
	$parser->parse_file($fh);

	1;
}

sub _file {
	my ($class, $file) = @_;
	if ( _INSTANCE($file, 'IO::File') ) {
		return $file;
	}
	unless ( $file and -f $file and -r _ ) {
		croak('Did not provide a readable file name');
	}
	my $fh = IO::File->new( $file )
		or croak("Failed to open PITA::Report file '$file'");
	return $fh;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-Report>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
