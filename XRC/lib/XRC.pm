package XRC;

use 5.008005;
use Moose        0.92;
use Params::Util 1.00 ();
use IO::File     1.14 ();
use XML::SAX     0.96 ();
use XRC::Size         ();
use XRC::Dialog       ();
use XRC::BoxSizer     ();
use XRC::Parser       ();

our $VERSION = '0.01';

has children => (
	is      => 'rw',
	isa     => "ArrayRef[XRC::Object]",
	default => sub { [ ] },
);





######################################################################
# Parsing Code

sub add_object {
	my $self = shift;
	unless ( Params::Util::_INSTANCE($_[0], 'XRC::Object') ) {
		die("Can only add a 'XRC::Object' object");
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
	my $handler = XRC::Parser->new( $self );
	my $parser  = XML::SAX::ParserFactory->parser(Handler => $handler);

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
