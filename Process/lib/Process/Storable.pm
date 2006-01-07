package Process::Storable;

# Process that is compatible with Storable after new, and after run.

use 5.005;
use strict;
use Storable ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.03';
}

1;

__END__

=pod

=head1 NAME

Process::Storable - Process object that is compatible with Storable

=head1 SYNOPSIS

  packate MyStorableProcess;
  
  use base 'Process::Storable',
           'Process';
  
  sub prepare {
      ...
  }
  
  sub run {
      ...
  }
  
  1;

=head1 DESCRIPTION

C<Process::Storable> provides the base for objects that can be
stored, or transported from place to place. It is not itself a
subclass of L<Process> so you will need to inherit from both.

Objects that inherit from C<Process::Storable> must follow the C<new>,
C<prepare>, C<run> rules much more strictly.

All platform-specific resource checking and binding must be done in
C<prepare>, so that after C<new> (but before C<prepare>) the object
can be stored via L<Storable> and later thawed, C<prepare>'ed and
C<run>, then stored via C<Storable> again after completion.

C<Process::Storable> is subclass (for now) of L<Process>.

=head1 METHODS

There is no change from the base C<Process> class.

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
