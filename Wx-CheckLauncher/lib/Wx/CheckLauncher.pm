package Wx::CheckLauncher;

=pod

=head1 NAME

Wx::Launcher - Ensure a Wx program is launched with the wxperl binary

=head1 SYNOPSIS

In your Wx-based application launcher

  #!/usr/bin/perl
  
  use strict;
  use Wx::Launcher;
  
  # Continue as normal...

=head1 DESCRIPTION

For reasons I fail to fully understand, on some platforms you cannot
launch a Wx-based application using the normal perl binary, but instead
must use an entirely seperate wxperl binary

If you are on a platform that needs F<wxperl>, and you are loaded by the
normal F<perl>, B<Wx::CheckLauncher> module will search around and try
to find the F<wxperl> binary, and then relaunch the same script using
it instead via C<exec>, with the same params and flags as the current
program was called with.

=head1 METHODS

There are no methods. You simply use the module as early as possible,
probably right after C<use strict;> and make sure to load it with
only default params.

Specifically, need must B<always> load it before you do anything in your
script, and with just a plain use call.

  # Use it like this ...
  use Wx::CheckLauncher;
  
  # ... not like this ...
  use Wx::CheckLauncher 'anything';
  
  # ... and not like this.
  use Wx::CheckLauncher ();

And that's all there is to do. The module should take care of the rest.

=cut

use 5.005;
use strict;
use File::Spec  ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub import {
	# Are we already running wxperl
	return 1 if $^X =~ /\bwxperl$/i;

	# We know Windows is OK
	return 1 if $^O eq 'MSWin32';

	# For the rest, can we find a wxperl binary?
	require File::Which;
	my $wxperl = File::Which::which('wxperl');
	print "# Restarting with wxperl...\n";
	exec "$wxperl $^X $0";
}

1;

=pod

=head1 TO DO

- Find alternative ways to launch a display on different platforms

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wx::CheckLauncher>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<Wx>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
