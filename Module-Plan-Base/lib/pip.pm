package pip;

=pod

=head1 NAME

pip - Console application for running "Perl Install Plan" (PIP) files

=head1 DESCRIPTION

A Perl Install Plan (PIP) file is a file that describes a set of
distributions to install, and integrates the installation of these
distributions with the CPAN installer.

The primary use of PIP files are for installing proprietary or non-CPAN
software that may still require the installation of a number of
distributions in order.

It can also be used to ensure specific versions of CPAN modules are
installed instead of the most current version.

PIP files are also extensible, with the first line of the file
specifying the name of the Perl class (which must be installed)
that implements the plan.

The simple L<Module::Plan::Lite> plan class is bundled with the main
distribution, and additional types can be installed if needed.

=head1 USAGE

The F<pip> command is used to install a PIP file and in the canonical
case is used as follows

  pip directory/myplan.pip

This command will load the plan file F<directory/myplan.pip>, create
the plan, and then execute it.

If only a directory name is given, F<pip> will look for a F<default.pip>
plan in the directory. Thus, all of the following are equivalent

  pip directory
  pip directory/
  pip directory/default.pip

If no target is provided at all, then the current directory will be used.
Thus, the following are equivalent

  pip
  pip .
  pip ./default.pip
  
=cut

use strict;
use File::Spec;
use Module::Plan::Base;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Main Function

sub main {
	# Create the plan object
	my $pip = @ARGV
		? shift(@ARGV)
		: File::Spec->curdir;
	if ( -d $pip ) {
		$pip = File::Spec->catfile( $pip, 'default.pip' );
	}
	unless ( -f $pip ) {
		error( "The plan file $pip does not exist" );
	}

	# Create the plan object
	my $plan = Module::Plan::Base->read( $pip );
	$plan->run;
}

sub error {
	print $_[0] . "\n";
	exit(255);
}

1;

=pod

=head1 SUPPORT

This module is stored in an Open Repository at the following address.

L<http://svn.phase-n.com/svn/cpan/trunk/Module-Plan-Base>

Write access to the repository is made available automatically to any
published CPAN author, and to most other volunteers on request.

If you are able to submit your bug report in the form of new (failing)
unit tests, or can apply your fix directly instead of submitting a patch,
you are B<strongly> encouraged to do so. The author currently maintains
over 100 modules and it may take some time to deal with non-Critical bug
reports or patches.

This will guarentee that your issue will be addressed in the next
release of the module.

If you cannot provide a direct test or fix, or don't have time to do so,
then regular bug reports are still accepted and appreciated via the CPAN
bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Plan-Base>

For other issues, for commercial enhancement and support, or to have your
write access enabled for the repository, contact the author at the email
address above.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Module::Plan::Base>, L<Module::Plan::Lite>, L<Module::Plan>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
