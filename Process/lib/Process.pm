package Process;

# Base class for objects that represent processes in the
# general sense.

use 5.005;
use strict;
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

# Default constructor
sub new {
	my $class = shift;
	bless { }, $class;
}

# Default prepare
sub prepare { 1 }

# Default execution
sub run { 1 }

1;

__END__

=pod

=head1 NAME

Process - Interface for objects that represent generic computational
processes

=head1 VERSION

Version 0.01 - Please note that this distribution is currently experimental

=head1 SYNOPSIS

  # Create the process
  my $object = MyProcess->new( ... ) or die("Invalid configuration format");
  
  # Initialize it
  $object->prepare or die("Configuration not supportable");
  
  # Execute the process
  $object->run or die("Error while trying to execute the process");

=head1 DESCRIPTION

There are a great number of situations in which you may want to
model a computational process as an object.

An implementation of this sort of object generally looks like the following
when somebody uses it.

  my $object = MyProcessClass->new( ... );
  
  my $rv = $object->run;
  
  if ( $rv ) {
      print "Thingy ran ok";
  } else {
      print "Failed to run thingy";
  }

The C<Process> family of classes is intented to be used as base classes
for these types of objects. They are used to help identify process
objects, and enforce a very limited API on these objects.

The main intent is to provide a common base for objects that will be
able to be used with various distributed processing systems. The scope
of these includes solutions to address the following scenarios.

=over 4

=item A single CPU on a single host

=item Multiple CPUs on a single host

=item Multiple hosts on a single network

=item Hosts distributed across the internet

=item Any processing resource accessible via any mechanism

=back

To put it another way, this family of classes is intended to addresses
the seperation of concerns between the processing of something, and the
results of something.

The actual ways in which the processes are run, and the handling of the
results of the process are outside the scope of these classes.

The C<Process> class itself is the root of all of these classes. In fact,
it is so abstract that it contains almost no functionality at all, and
serves primarily to indicate that an object obeys the general rules of
a C<Process> class.

=head1 METHODS

=head2 new

  my $object = MyClass->new( $configuration );
  if ( $object and $object->isa('Process') ) {
  	print "Object created.\n";
  } else {
  	print "Configuration not valid.\n";
  }

The C<new> constructor is required for all classes. It may or may not
take arbitrary params, with specifics to be determined by each class.

A default implementation which ignores params and creates an empty object
of a C<HASH> type is provided as a convenience. However it should not
be assumed that all objects will be a C<HASH> type.

For objects that subclass only the base C<Process> class, and are not
also subclasses of things like L<Process::Storable>, the param-checking
done in C<new> should be thorough and and objects should be correct,
with problems at C<run>-time the exception rather than the rule.

Returns a new C<Process> object on success.

For blame-free "Cannot support process on this host" failure, return
false.

For blamed failure, may return a string or any other value that is not
itself a C<Process> object.

However, if you need to communicate failure, you should consider
putting your param-checking in a C<prepare> method and attaching the
failure messages to the object itself. You should NEVER store errors
in the class, as all C<Process> classes are forbidden to use class-level
data storage.

=head2 prepare

  unless ( $object->prepare ) {
  	# Failed
  	
The C<prepare> method is used to check object params and bind platform
resources.

The concept of object creation in C<new> is seperated from the concept
of checking and binding to support storage and transportation in some
subclasses.

Because many systems that make use of C<Process> do so through the
desire to push process requests across a network and have them executed
on a remote host, C<Process> provides the C<prepare> method provides
a means to seperate checking of the params for general correctness
from checking of params relative to the system the process is being
run on. It additionally provides a good way to have errors remain
attached to the object, and have them transported back across to the
requesting host.

Execution platforms are generally required to call C<run> immediately
after C<prepare>. As a result you should feel free to lock files and
hold socket ports as they B<will> be used immediately, and thus the only
execution errors coming from C<run> should be due to unexpected changes
or race-condition issues.

To restate, all possibly binding and checking should be done in C<prepare>
if at possible.

A default null implementation is provided for you which does nothing
and returns true.

Returns true if all params check out ok, and all system resources
needed for the execution are bound correctly.

Returns false if not, with any errors to be propogated via storage in the
object itself.

The object should B<not> return errors via exceptions. If you expect
something you yourself use to potentially result in an exception, you
should trap the exception and return false.

=head2 run

  my $rv = $object->run;
  if ( $rv ) {
  	print "Process completed successfully\n";
  } else {
  	print "Process interupted, or unexpected error\n";
  }

The C<run> method is used to execute the process. It should do all
appropriate processing and calculation and detach from all relevant
resources before returning.

If your process has any results, they should be stored inside the
C<Process> object itself, and retrieved via an additional method
of your choice after the C<run> call.

A default implementation which does nothing and returns true is
provided.

Returns true of the process was completed fully, regardless of any
results from the process.

Returns false if the process was interrupted, or an unexpected
error occurs.

If the process returns false, it should not be assumed that the process
can be restarted or rerun. It should be discarded or returned to the
requestor to check for specific errors.

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
