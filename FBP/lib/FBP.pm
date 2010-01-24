package FBP;

=pod

=head1 NAME

FBP - Parser and Object Model for wxFormBuilder Project Files (.fpb files)

=head1 SYNOPSIS

  my $object = FBP.pm->new(
      foo  => 'bar',
      flag => 1,
  );
  
  $object->dummy;

=head1 DESCRIPTION

The author was too lazy to write a description.

=head1 METHODS

=cut

use 5.008005;
use Moose        0.92;
use Params::Util 1.00 ();
use IO::File     1.14 ();
use XML::SAX     0.96 ();
use FBP::Parser       ();
use FBP::Project      ();
use FBP::Dialog       ();
use FBP::BoxSizer     ();
use FBP::Button       ();
use FBP::SizerItem    ();
use FBP::StaticText   ();
use FBP::StaticLine   ();

our $VERSION = '0.01';

has children => (
	is      => 'rw',
	isa     => "ArrayRef[FBP::Object]",
	default => sub { [ ] },
);





######################################################################
# Parsing Code

sub add_object {
	my $self = shift;
	unless ( Params::Util::_INSTANCE($_[0], 'FBP::Object') ) {
		die("Can only add a 'FBP::Object' object");
	}
	my $objects = $self->children;
	push @$objects, shift;
	return 1;
}

sub parse_file {
	my $self = shift;
	my $file = shift;
	unless ( -f $file and -r $file ) {
		die("Missing or unreadable file '$file'");
	}

	# Open the file
	my $fh = IO::File->new( $file );
	unless ( $fh ) {
		die("Failed to open file '$file'");
	}

	# Create the parser
	my $handler = FBP::Parser->new($self);
	my $parser  = XML::SAX::ParserFactory->parser(
		Handler => $handler,
	);

	# Parse the file
	eval {
		$parser->parse_file( $fh );
	};
	if ( $@ ) {
		die("Error while parsing '$file': $@");
	}

	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FBP>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
