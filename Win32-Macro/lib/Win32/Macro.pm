package Win32::Macro;

=pod

=head1 NAME

Win32::Macro - The Win32 Macro System

=head2 DESCRIPTION

B<THIS MODULE IS INCOMPLETE AND HIGHLY EXPERIMENTAL. THIS VERSION HAS BEEN
UPLOADED FOR DEMONSTRATION AND REVIEW PURPOSES ONLY, AND MAY CHANGE
DRAMATICALLY WITH NO NOTICE.>

B<YOU HAVE BEEN WARNED!>

B<Win32::Macro> is a module that implements a "Perl style" convenience
layer that makes it easier to implement various types of macros on
Windows, and do other sorts of Win32 GUI programming.

This not only covers the use of the API, but also other factors such
as easy of installation. Win32::Macro only makes use of
CPAN-installable dependencies, so that a Win32::Macro-based module
or application can itself be installed directly from CPAN on any
Windows Perl installation that supports installing CPAN modules.

More details to follow...

=cut

use 5.006;
use strict;
use Win32::Macro::Internals;
use Win32::Macro::Window;

our $VERSION = '0.01';





#####################################################################
# Convenience Functions

sub desktop_window {
	my $hwnd = Win32::Macro::Internals::GetDesktopWindow();
	Win32::Macro::Window->new( $hwnd );
}

1;

=pod

=head1 SEE ALSO

L<Win32::Screenshot>, L<Win32::GUI>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
