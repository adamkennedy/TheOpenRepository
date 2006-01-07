package Process::Launcher;

use strict;
use base 'Exporter';
use Params::Util qw{_CLASS _INSTANCE};

use vars qw{$VERSION @EXPORT};
BEGIN {
	$VERSION = '0.01';
	@EXPORT  = qw{run run3 storable};
}





#####################################################################
# Interface Functions

sub run() {
	my $class  = load(shift @ARGV);
	my $object = $class->new( @ARGV )
		or fail("$class->new returned false");
	execute($object);
	exit(0);
}

sub run3() {
	my $class = load(shift @ARGV);

	# Load the params from STDIN
	my @params = ();
	SCOPE: {
		# Implementation recycled from Config::Tiny
		local $/;
		my $input = <STDIN>;
		foreach ( split /(?:\015{1,2}\012|\015|\012)/, $input ) {
			if ( /^\s*([^=]+?)\s*=\s*(.*?)\s*$/ ) {
				push @params, $1, $2;
				next;
			}
			fail("Input did not match the correct format");
		}
	}

	# Create the process
	my $object = $class->new( @params );
	unless ( $object ) {
		fail("$class->new returned false");
	}

	# Run it
	execute($object);

	exit(0);	
}

sub storable() {
	# Load the Storable object from STDIN
	require Storable;
	my $object = Storable::fd_retrieve(\*STDIN);
	my $class  = load(ref($object));
	unless ( _INSTANCE($object, 'Process') ) {
		fail("$class object is not a Process object");
	}
	unless ( _INSTANCE($object, 'Process::Storable') ) {
		fail("$class object is not a Process::Storable object");
	}

	# Execute the object
	execute($object);

	# Return the object after execution
	Storable::nstore_fd( $object, \*STDOUT );

	exit(0);
}





#####################################################################
# Support Functions

sub execute($) {
	my $object = shift;
	my $class  = ref($object);
	unless ( $object->prepare ) {
		fail("$class->prepare returned false");
	}
	unless ( $object->run ) {
		fail("$class->run returned false");
	}
	print "OK\n";
	1;	
}

sub load($) {
	my $class = shift;
	unless ( _CLASS($class) ) {
		fail("Did not provide a valid class as first argument");
	}
	eval "require $class";
	fail("Error loading $class: $@") if $@;
	unless ( $class->isa('Process') ) {
		fail("$class is not a Process class");
	}
	$class;
}

sub fail($) {
	my $message = shift;
	$message =~ s/\n$//;
	print "FAIL - $message\n";
	exit(0);
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

=head1 FUNCTIONS

All functions are imported into the callers by default.

=head2 run

The C<run> function creates an object based on the arguments passed
to the program on the command line.

The first param is take as the L<Process> class and loaded, and the
rest of the params are passed directly to the constructor.

Note that this does mean you can't pass anything more complex than
simple string pairs. If you need something more complex, try the
C<storable> function below.

Prints one line of output at the end of the process run.

  # Prints the following if the process completed correctly
  OK
  
  # Prints the following if the process does not complete
  FAIL - reason

=head2 run3

The C<run3> function is similar to the C<run> function but assumes
you are launching the process via something that makes it easy to
pass in params via C<STDIN>, such as L<IPC::Run3> (recommended)

It takes a single param of the L<Process> class.

It then readsa series of key-value pairs from C<STDIN> in the form

  param1=value
  param2=value

At the end of the input, the key/value pairs are passed to the
constructor, and from there the function behaves identically to
C<run> above, including output.

=head2 storable

The C<storable> function is more robust and thorough again.

It reads data from C<STDIN> and then thaws that via L<Storable>.

The data is expected to thaw to an already-constructed L<Process>
object that is also a L<Process::Storable>.

This object has C<prepare> and then C<run> called on it.

The same C<OK> or C<FAIL> line will be written as above, but after
that first line, the completed object will be frozen via
the C<Storable::nstore_fd> function and written to C<STDOUT> as
well.

The intent is that you create your process in your main process,
and then hand it off to another Perl instance for execution, and
then optionally return it to handle the results.

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
