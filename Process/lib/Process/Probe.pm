package Process::Probe;

=pod

=head1 NAME

Process::Probe - Process to test if any named classes are installed

=head1 SYNOPSIS

  my $probe = Process::Probe->new( qw{
      My::Process
      CPAN::Module::Process
      Something::Else
  } );
  
  $probe->run;
  
  # Lists of classes
  my @yep   = $probe->available;
  my @nope  = $probe->unavailable;
  my @maybe = $probe->unknown;
  
  # Test for single class with any of the above
  if ( $probe->available('My::Process') ) {
      print "My::Process is available\n";
  }

=head1 DESCRIPTION

B<Process::Probe> is a simple and standardised class available that is
available with the core L<Process> distribution. It is used to probe
a host to determine whether or not the remote host has certain process
classes installed.

By default, the object will search through the system's include path to
find the .pm files that match the particular classes.

Typical examples of using the default functionality could include
executing a B<Process::Probe> object via a SSH login on a remote host
to determine which of a set of desired classes exist on the remote host.

The probe will ONLY check for the existance of classes that are in the
unknown state at the time the C<run> method is called.

In scenarios where the requestor does not have direct execution rights
on the remote host, and the request is being marshalled via a server
process, this allows security code on the server to preset forbidden
classes to no before the probe is run, or to otherwise manipulate the
"answer" to the "question" that B<Process::Probe> represents. 

No functionality is provided to query ALL the C<Process>-compatible
classes on a remote host. This is intentional. It prevents very
disk-intensive scans, protects remote host against hostile requests,
and prevents the use of these objects en-mass as a denial of service.

=head1 METHODS

=cut

use strict;
use base qw{
	Process::
};

1;
