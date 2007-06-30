package Task::TWiki;

use 5.005003;
use strict;
use vars qw{$VERSION};
BEGIN {
	$VERSION = '4.000001';
}

1;

__END__

=pod

=head1 NAME

Task::TWiki - Task package to help install the dependencies for TWiki

=head1 SYNOPSIS

  > perl -MCPAN -e "install Task::TWiki"
  
  ... or if you have the "cpan" program ...
  
  > cpan install Task::TWiki

=head1 DESCRIPTION

L<TWiki|http://twiki.org/> is a Wiki for corporate types (and others), that is
not (yet) distributed via CPAN.

As such, it's install instructions give a manual list of modules you are
expected to install or upgrade. In fact, the list looks just like you'd find
inside a L<Task> module, except it's not one, so you have to install by hand.

So to make this a little easier, I've (unofficially) implement the CPAN module
dependency rules for TWiki as a task module, so people with the CPAN shell
working can take the shortcut of just install B<Task::TWiki> and it will walk
you through installing the CPAN modules needed for TWiki.

The version is set to match the TWiki release.

So for the current TWiki 4.0.1 I've created Task::Twiki as 4.000001 (which is
the longhand form of 4.0.1 in Perl, as each number becomes a group of three)

Also, although this Task module will check for the external programs needed,
it is not currently capable of checking the versions of these programs.

You may wish to double-check that programs are indeed of the correct version.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

If the TWiki developers want to take this over at some point to upgrade
it for newer versions, let me know.

=head1 SEE ALSO

L<Task>, L<http://twiki.org/>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
