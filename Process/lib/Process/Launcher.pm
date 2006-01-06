package Process::Launcher;

use strict;
use base 'Exporter';
use Config::Tiny ();
use Params::Util ':ALL';

use vars qw{$VERSION @EXPORT};
BEGIN {
	$VERSION = '0.01';
	@EXPORT  = qw{run run3 storable};
}





#####################################################################
# Interface Functions

sub run() {
	# Load the class param
	my $class = load(shift @ARGV);

}

sub run3() {
	# Load the class param
	my $class = load(shift @ARGV);
	
}

sub storable() {
	
}





#####################################################################
# Support Functions

sub load($) {
	my $class = shift;
	unless ( _CLASS($class) ) {
		fail("Did not provide a valid class as first argument");
	}
	eval "require $class";
	fail("Error loading $class: $@") if $@;
	unless ( $class->isa('Process') ) {
		fail("$class is 
	}
}

sub fail($) {
	
}

1;

__END__

=pod

=head1 NAME

Process::Launcher - Execute Process objects from the command line

=head1 SYNOPSIS

  # Create from passed params and run
  perl -MProcess::Launcher -e run MyProcessClass param value
  
  # Create from STDIN params and run
  perl -MProcess::Launcher -e run3 MyProcessClass
  
  # Thaw via Storable from STDIN, and freeze back after to STDOUT
  perl -MProcess::Launcher -e storable

=head1 DESCRIPTION

The C<Process::Launcher> module provides a mechanism for launching
and running a L<Process>-compatible object from the command line,
and returning the results.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Process>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
