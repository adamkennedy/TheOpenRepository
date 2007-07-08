package pip;

use 5.005;
use strict;
use File::Spec         ();
use File::Temp         ();
use File::Which        ();
use Getopt::Long       ();
use Module::Plan::Base ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}





#####################################################################
# Main Function

# Save a copy of @ARGV for error messages
my $install = 0;
Getopt::Long::GetOptions(
	install => \$install,
);

sub main {
	unless ( @ARGV ) {
		error("Did not provide a command");
	}

	# If the first argument is a file, install it
	if ( -f $ARGV[0] ) {
		return install_any(@ARGV);
	}

}

sub install_any {
	# Load the plan
	my $plan = read_any(@_);

	# Run it
	$plan->run;

	return 1;
}

sub read_any {
	my $param = $_[0];

	# If the first argument is a p5i file, hand off to read
	if ( $param =~ /\.p5i$/ ) {
		return read_p5i(@_);
	}

	# If the first argument is a tar.gz file, hand off to install
	if ( $param =~ /\.tar\.gz$/ ) {
		return read_tarball(@_);
	}

	# If the first argument is a p5z file, hand off to instal
	if ( $param =~ /\.p5z$/ ) {
		return read_p5z(@_);
	}

	error("Unknown or unsupported file '$param'");
}

# Create the plan object from a file
sub read_p5i {
	my $pip = @_
		? shift
		: File::Spec->curdir;
	if ( -d $pip ) {
		$pip = File::Spec->catfile( $pip, 'default.p5i' );
	}
	unless ( -f $pip ) {
		error( "The plan file $pip does not exist" );
	}

	# Create the plan object
	my $plan = eval {
		Module::Plan::Base->read( $pip );
	};
	if ( $@ ) {
		unless ( $@ =~ /The sources directory is not owned by the current user/ ) {
			# Rethrow the error
			die $@;
		}

		# Generate an appropriate error
		my @msg = (
			"The current user does not control the default CPAN client",
			);
		if ( File::Which::which('sudo') ) {
			my $cmd = join(' ', 'sudo', '-H', $0, @_);
			push @msg, "You may need to try again with the following command:";
			push @msg, "";
			push @msg, "  $cmd";
		}
		error( @msg );
	}

	return $plan;
}

sub read_tarball {
	require Module::Plan::Lite;
	my $targz = shift;
	Module::Plan::Lite->new(
		p5i   => 'default.p5i',
		lines => [ '', $targz ],
		);
}

sub read_p5z {
	my $p5z = shift;

	# Create the temp directory
	my $dir   = File::Temp::tempdir( CLEANUP => 1 );
	my $pushd = File::pushd::pushd( $dir );

	# Extract the tarball
	require Archive::Tar;
	my @files = Archive::Tar->extract_archive( $p5z, 1 );
	unless ( @archives ) 
		error( "Failed to extract P5Z file: " . Archive::Tar->error );
	}

	# Find the plan
	my $path = File::Spec->catfile( $dir, 'default.p5i' );
	unless ( -f $path ) {
		error("P5Z file did not contain a default.p5i");
	}

	# Load the plan
	return read_p5i( $path );
}





#####################################################################
# Support Functions

sub error {
	print "\n";
	print map { $_ . "\n" } @_;
	exit(255);
}

1;

=pod

=head1 NAME

pip - Console application for running Perl 5 Installer (P5I) files

=head1 DESCRIPTION

A Perl 5 Installer (P5I) file is a small script-like file that
describes a set of distributions to install, and integrates the
installation of these distributions with the CPAN installer.

The pip ("Perl Installation Program") command is used to install the
distributions described by the p5i script.

The primary use of P5I files are for installing proprietary or
non-CPAN software that may still require the installation of a number of
distributions in order.

It can also be used to ensure specific versions of CPAN modules are
installed instead of the most current version.

P5I files are also extensible, with the first line of the file
specifying the name of the Perl class that implements the plan.

For the moment, the class described at the top of the P5I file must
be installed.

The simple L<Module::Plan::Lite> plan class is bundled with the main
distribution, and additional types can be installed if needed.

=head1 USAGE

The F<pip> command is used to install a P5I file and in the canonical
case is used as follows

  pip directory/myplan.p5i

This command will load the plan file F<directory/myplan.p5i>, create
the plan, and then execute it.

If only a directory name is given, F<pip> will look for a F<default.p5i>
plan in the directory. Thus, all of the following are equivalent

  pip directory
  pip directory/
  pip directory/default.p5i

If no target is provided at all, then the current directory will be used.
Thus, the following are equivalent

  pip
  pip .
  pip default.p5i
  pip ./default.p5i

=head2 Syntax of a plan file

Initially, the only plan is available is the L<Module::Plan::Lite>
(MPL) plan.

A typical MPL plan will look like the following

  # myplan.p5i
  Module::Plan::Lite
  
  Process-0.17.tar.gz
  YAML-Tiny-0.10.tar.gz

=head2 Direct installation of a single file with -i or --install

With the functionality available in F<pip>, you can find that sometimes
you don't even want to make a file at all, you just want to install a
single tarball.

The C<-i> option lets you pass the name of a single file and it will treat
it as an installer for that single file. For example, the following are
equivalent.

  # Installing with the -i|--install option
  > pip -i Process-0.17.tar.gz
  > pip --install Process-0.17.tar.gz
  
  # Installing from the file as normal
  > pip ./default.p5i
  
  # myplan.p5i
  Module::Plan::Lite
  
  Process-0.17.tar.gz

The C<-i> option can be used with any single value supported by
L<Module::Plan::Lite> (see above).

=head1 SUPPORT

This module is stored in an Open Repository at the following address.

L<http://svn.ali.as/cpan/trunk/pip>

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

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=pip>

For other issues, for commercial enhancement and support, or to have your
write access enabled for the repository, contact the author at the email
address above.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Module::Plan::Base>, L<Module::Plan::Lite>, L<Module::Plan>

=head1 COPYRIGHT

Copyright 2006 - 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
