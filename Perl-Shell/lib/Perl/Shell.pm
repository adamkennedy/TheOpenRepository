package Perl::Shell;

=pod

=head1 NAME

Perl::Shell - A Python-style "command line interpreter" for Perl

=head1 SYNOPSIS

  C:\Document and Settings\adamk> perlthon
  
  >>> print "Hello World!\n";
  Hello World!
  
  >>> 

=head1 DESCRIPTION

B<THIS MODULE IS HIGHLY EXPERIMENTAL AND SUBJECT TO CHANGE.>

B<YOU HAVE BEEN WARNED>

This module provides an implementation of a "command line interpreter"
in the style of the Python equivalent.

=head1 FUNCTIONS

=cut

use 5.006;
use strict;
use Carp                 ();
use Params::Util         '_INSTANCE';
use Term::ReadLine       ();
use Lexical::Persistence ();
use PPI                  ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Shell Functions

=pod

=head2 shell

  Perl::Shell::shell();

  The only public function available is the C<shell> function.

  It takes no arguments and starts up the shell.

=cut

sub shell {
	my $scope = Lexical::Persistence->new;

	print "\n";
	my @buffer = ();
	foreach ( 1 .. 10 ) {    
		# Read in a line
		my $line = _term_readline(@buffer ? '... ' : '>>> ');
		unless ( defined $line ) {
			die "Failed to readline\n";
		}
		push @buffer, $line;

		# Continue if the statement is not complete
		next unless _is_complete( @buffer );

		# Execute the code
		my $code = join "\n", @buffer;
		my @rv   = $scope->do( $code );
		print "ERROR: $@" if $@;
		print "\n";

		# Clean up for the next command
		@buffer = ();
	}
}

my $term;
sub _term_readline {
	my $prompt = shift;
	if ( -t STDIN ) {
		unless ( $term ) {
			require Term::ReadLine;
			$term = Term::ReadLine->new('Perl-Shell');
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
sub _is_complete {
	my $string = join "\n", @_;

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
	unless ( _INSTANCE($document->child(-1), 'PPI::Statement::Null') ) {
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

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Shell>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 ACKNOWLEGEMENTS

Thanks to Ingy for suggesting that this module should exist.

=head1 COPYRIGHT

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
