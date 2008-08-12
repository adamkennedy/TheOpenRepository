package Perl::Shell;

use 5.006;
use strict;
use Carp         ();
use Params::Util '_INSTANCE';
use PPI          ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Shell Functions

sub shell {
	my @buffer = ();
	foreach ( 1 .. 10 ) {    
		# Read in a line
		my $line = term_readline(@buffer ? '...' : '>>>');
		unless ( defined $line ) {
			die "Failed to readline\n";
		}
		push @buffer, $line;

		# Continue if the statement is not complete
		next unless complete( @buffer );

		# Execute the code
		my $code = join '', @buffer;
		my @rv   = eval $code;
		print "ERROR: $@" if $@;
		print "\n";

		# Clean up for the next command
		@buffer = ();
	}
}

my $term;
sub term_readline {
	my $prompt = shift;
	if ( -t STDIN ) {
		unless ( $term ) {
			require Term::Readline;
			$term = Term::Readline->new('Perl-Shell');
		}
		return $term->readline($prompt);
	} else {
		print $prompt;
		my $line = <>; 
		chomp if defined $line;
		return $line;
	}
}





#####################################################################
# Support Functions

# To be "complete" a fragment of Perl must have no open structures
# and terminate with a clear statement end.
sub complete {
	my $string = join '', @_;

	# As a quick and dirty way to check for a clear statement
	# end, we append a semi-colon to the string. If this is
	# subsequently parsed as a null statement, we know the
	# string is a complete document.
	# The newline is added to get us out of comment blocks
	# and similar line-specific things.
	$string .= "\n;";

	# Parse the string into a document
	my $document = PPI::Document->new( \$string );
	unless ( $document ) {
		die "PPI failed to parse document";
	}

	# The document must end in a null statement
	unless ( _INSTANCE($document->schild(-1), 'PPI::Statement::Null') ) {
		return '';
	}

	# The document must not contain any open braces
	$document->find_any( sub {
		$_[1]->isa('PPI::Structure') and ! $_[1]->finish
	} ) and return '';

	# The document is complete
	return 1;
}

1;
