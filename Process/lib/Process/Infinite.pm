package Process::Infinite;

use strict;
use base 'Process';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

1;

__END__

=pod

=head1 NAME

Process::Infinite - Base class for processes that do not naturally end

=head1 DESCRIPTION

C<Process::Infinite> is a base class for L<Process> objects that will
not naturally finish without provocation for outside the process.

Examples of this are system "daemons" and servers of various types.

At the present time this class is indicative only. It contains no
additional functionality.

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
