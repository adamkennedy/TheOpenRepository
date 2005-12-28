package PITA::Report;

=pod

=head1 NAME

PITA::Report - Create, load, save and manipulate PITA-XML reports

=head1 STATUS

B<This is an experimental release for demonstration purposes only.>

B<Please note the .xsd schema file may not install correctly as yet.>

=head1 SYNOPSIS

  # Create a new empty report file
  my $report = PITA::Report->new;
  
  # Load an existing report
  my $report = PITA::Report->new('filename.pita');

=head1 DESCRIPTION

The Perl Image Testing Architecture (PITA) is designed to provide a
highly modular and flexible set of components for doing testing of Perl
distributions.

Within PITA, the L<PITA::Report> module provides the primary method of
reporting the results of installation attempts.

The L<PITA::Report> class itself provides a way to create a set of
testing results, and then store (and later recover) these results as
you wish to a file.

A single PITA report file consists of structured XML that can be validated
against a known schema, while storing a large amount of testing data without
any ambiguity or the edge cases you may find in a YAML, email or text-file
file.

The ability to take testing results from another arbitrary user and validate
them also makes implementing a parser very simple, and thus allows the
creation of aggregators and processing systems without undue thoughts about
the report files themselves.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp                    ();
use Params::Util            ':ALL';
use IO::File                ();
use IO::String              ();
use File::Flock             ();
use File::ShareDir          ();
use XML::SAX::ParserFactory ();
use XML::Validator::Schema  ();
use PITA::Report::Install   ();
use PITA::Report::Request   ();
use PITA::Report::Platform  ();
use PITA::Report::Command   ();
use PITA::Report::Test      ();
use PITA::Report::SAXParser ();
use PITA::Report::SAXDriver ();

use vars qw{$VERSION $SCHEMA};
BEGIN {
	$VERSION = '0.02';
}

# Temporary Hack:
# IO::String looks like a duck, but we need it to be a real duck. So lets
# make it a duck if it didn't turn into a duck while we weren't looking.
unless ( @IO::String::ISA ) {
	@IO::String::ISA = qw{IO::Handle IO::Seekable};
}

# The XML Schema File
# Locate the Schema at use-time (instead of compile-time)
$SCHEMA = File::ShareDir::dist_file('PITA-Report', 'PITA-Report.xsd');

# While in development, use a version-specific namespace.
# In theory, this ensures documents are only truly valid with the
# version they were created with.
use constant XMLNS => "http://ali.as/xml/schema/pita-xml/$VERSION";





#####################################################################
# Constructor and Accessors

=pod

=head1 new

  # Create a new (empty) report file
  $empty = PITA::Report->new;
  
  # Load an existing file
  $report = PITA::Report->new( 'filename.pita' );
  $report = PITA::Report->new( $filehandle     );

The C<new> constructor takes a file name or handle and parses it to create
a new C<PITA::Report> object.

If passed a file handle object, it B<must> be seekable (an L<IO::Seekable>
subclass) as the file will need to be read twice. The first pass validates
the file against the schema, and the second populates the object with
L<PITA::Report::Install> reports.

If passed no param, it creates a new empty report, ready for you to fill
with L<PITA::Report::Install> objects you will generate yourself.

Returns a new C<PITA::Report> object, or dies on error (most often due to
problems validating an incorrect file).

=cut

sub new {
	my $class = shift;

	# No params creates a new empty object
	my $self = bless {
		installs => [],
		}, $class;
	return $self unless @_;

	# Validate the document
	my $fh = $self->_FH(shift);
	# $class->validate( $fh );

	# Reset the file handle for the next pass
	$fh->seek( 0, 0 ) or Carp::croak(
		'Failed to reset file after validation (seek to 0)'
		);

	# Build the object from the file
	my $parser = XML::SAX::ParserFactory->parser(
		Handler => PITA::Report::SAXParser->new( $self ),
		);
        $parser->parse_file($fh);

	$self;
}

=pod

=head2 validate

  # Validate a file without loading it
  PITA::Report->validate( 'filename.pita' );
  PITA::Report->validate( $filehandle     );

The C<validate> static method provides standalone validation of
a file or file handle, without creating a C<PITA::Report> object.

Returns true, or dies if it fails to validate the file or file handle.

=cut

sub validate {
	my $class = shift;
	my $fh    = $class->_FH(shift);

	# Create the validator
	my $parser = XML::SAX::ParserFactory->parser(
		Handler => XML::Validator::Schema->new(
			file => $SCHEMA,
			),
		);

	# Validate the document
	$parser->parse_file( $fh );

	1;
}

=pod

=head2 add_install

  # Add a new install object to the report
  $report->add_install( $install );

All C<PITA::Report> files can contain more than one install report.

The C<add_install> method takes a single L<PITA::Report::Install> object
as a parameter and adds it to the C<PITA::Report> object.

=cut

sub add_install {
	my $self    = shift;
	my $install = _INSTANCE(shift, 'PITA::Report::Install')
		or Carp::croak('Did not provide a PITA::Report::Install object');

	# Add it to the array
	push @{$self->{installs}}, $install;

	1;
}

=pod

=head2 installs

The C<installs> method returns all of the L<PITA::Report::Install> objects
from the C<PITA::Report> as a list.

=cut

sub installs {
	return (@{$_[0]->{installs}});
}

=pod

=head2 write

  my $output = '';
  $report->write( \$output        );
  $report->write( 'filename.pita' );

The C<write> method is used to save the report out to a named file.

It takes a single parameter, which can be either an XML SAX Handler
(any object that C<isa> L<XML::SAX::Base>) or any value that is
legal to pass as the C<Output> parameter to L<XML::SAX::Writer>'s
C<new> constructor.

Returns true when the file is written, or dies on error.

=cut

sub write {
	my $self   = shift;

	# Prepate the driver params
	my @params = _INSTANCE($_[0], 'XML::SAX::Base')
		? ( Handler => shift )
		: defined($_[0])
			? ( Output  => shift )
			: Carp::croak("Did not provide an output destination to ->write");

	# Create the SAX Driver
	my $driver = PITA::Report::SAXDriver->new( @params )
		or die("Failed to create SAXDriver for report");

	# Parse ourself with the driver to driver the writing
	# of the output.
	$driver->parse( $self );

	1;
}





#####################################################################
# Support Methods

sub _FH {
	my ($class, $file) = @_;
	if ( _SCALAR($file) ) {
		$file = IO::String->new( $file );
	}
	if ( _INSTANCE($file, 'IO::Seekable') ) {
		if ( _INSTANCE($file, 'IO::Seekable') or $file->can('seek') ) {
			# Reset the file handle
			$file->seek( 0, 0 ) or Carp::croak(
				'Failed to reset file handle (seek to 0)',
				);
			return $file;
		}
		Carp::croak('PITA::Report requires a seekable handle');
	}
	unless ( defined $file and ! ref $file and length $file ) {
		Carp::croak('Did not provide a file name or handle');
	}
	unless ( $file and -f $file and -r _ ) {
		Carp::croak('Did not provide a readable file name');
	}
	my $fh = IO::File->new( $file );
	unless ( $fh ) {
		 Carp::croak("Failed to open PITA::Report file '$file'");
	}
	$fh;
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

The Perl Image-based Testing Architecture (L<http://ali.as/pita/>)

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
