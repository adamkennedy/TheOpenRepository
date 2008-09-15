package Debug::Eval;

=pod

=head1 NAME

Debug::Eval - Allows you to debug string evals

=head1 SYNOPSIS

  use Debug::Eval;
  
  eval "print 'Hello World!';";

=head1 DESCRIPTION

=cut

use 5.006;
use strict;
use Exporter   ();
use File::Temp ();

use vars qw{$VERSION @ISA @EXPORT $TRACE $UNLINK};
BEGIN {
	$VERSION = '1.00';
	@ISA     = 'Exporter';
	@EXPORT  = 'eval';
	$TRACE   = 'STDERR' unless defined $TRACE;
	$UNLINK  = 1        unless defined $UNLINK;
}

# Compile the combined code via a temp file
sub eval {
	my ($fh, $filename) = File::Temp::tempfile();
	$fh->print("$_[0]") or die "print: $!";
	close( $fh )        or die "close: $!";
	my $message = "# require $filename\n";
	if ( defined $TRACE and not ref $TRACE ) {
		print STDOUT $message if $TRACE eq 'STDOUT';
		print STDERR $message if $TRACE eq 'STDERR';
	} elsif ( $TRACE ) {
		$TRACE->print($message);
	}
	require $filename;
	unlink $filename if $UNLINK;
}

1;
