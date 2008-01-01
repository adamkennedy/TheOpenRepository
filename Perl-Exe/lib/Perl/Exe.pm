package Perl::Exe;

=pod

=head1 NAME

Perl::Exe - Find the perl executable that is currently running

=head1 SYNOPSIS

  # Locate the current perl
  my $perl = Perl::Exe::find;
  
  # Execute something in a child perl
  Perl::Exe::run3( [ '-e', 'print "Hello World!\n";' ] );

=head1 DESCRIPTION

Although Perl provides the $^X variable, which describes the currently
running application, it is not a reliable cross-platform method to
use if you wish to execute some delegate the execution of code to a
child instance of the same Perl interpreter currently running.

That requires a bit more work, and in a few case some quite esoteric
tricks.

The new Perl module build system L<Module::Build> has some
quite sophisticated code for locating the current Perl.

Unfortunately, it is not accesible directly (outside of installing
a module) and it requires you to install an entire build system (with
all the requisite time, load overhead and risk of failed tests) to
answer a relatively simple question.

L<Perl::Exe> is a port of the L<Module::Build> C<find_perl_interpreter>
method into a standalone form. It has also been refactored to simplify
the code slightly, remove the special cases needed when building
inside the Perl core, and uses L<IPC::Run3> instead of the magic
platform-sensing backtick/forking logic in L<Module::Build>.

The result is a light-weight module with a very simple API that
makes it easy to locate, or run something with, the current interpreter.

=head1 FUNCTIONS

For simply future maintenance and improve readability, B<Perl::Exe>
functions are not exportable into your own namespace.

However, to make up for this, the functions have been named in an
exremely readable and straight-forward way (and the module name is
short) so using the full function names should not be a burdon.

=cut

use 5.005;
use strict;
use Config         ();
use File::Spec     ();
use File::Basename ();
use IPC::Run3      ();

use vars qw{$VERSION $EXE};
BEGIN {
	$VERSION = '0.01';

	# Declare $EXE as a global to allow
	# for testing and master-manipulator hackery.
	# However, don't document it in case I ever
	# wan't to move it back to a package-lexical.
	$EXE = undef unless defined $EXE;
}

sub find     ();
sub discover ();
sub is       ($);





#####################################################################
# Main Functions

=pod

=head2 find

  my $perl = Perl::Exe::find;

The C<Perl::Exe::find> function is the main way to locate the path of the
current Perl interpreter.

It takes no parameters, and locates the Perl interpreter, caching the
result and returning it as a simple string.

If the current Perl interpreter cannot be located, an exception is
thrown.

=cut

sub find () {
	$EXE or $EXE = discover;
}

=pod

=head2 discover

  my $perl = Perl::Exe::find;

The C<Perl::Exe::discover> function is the direct method for location the
current Perl interpreter, and contains the bulk of the logic.

You should only call C<Perl::Exe::discover> directly if you intentionally
want to avoid the cache and make a completely fresh attempt to determine
the location of the Perl interpreter.

It takes no parameters, and locates the Perl interpreter, returning the
path as a simple string and throwing an exception if the interpreter
cannot be located.

The C<Perl::Exe::discover> function is a direct port of the private
method L<Module::Build::Base::_discover_perl_interpreter>.

=cut

# Simplified version of Module::Build::Base::_discover_perl_interpreter
sub discover () {
	my $perl = $^X;
	my $name = File::Basename::basename($perl);

	# Try 1, Check $^X for absolute path
	my @potential = ();
	if ( File::Spec->file_name_is_absolute($perl) ) {
		push @potential, $perl;
	}

	# Try 2, Check $^X for a valid relative path
	my $abs_perl = File::Spec->rel2abs($perl);
	push @potential, $abs_perl;

	# Try 3, Last ditch effort: These two option use hackery to try to locate
	# a suitable perl.
	# ADAMK: Ditched the core version 3.A and kept the non-core one

	# Try 3.B, First look in $Config{perlpath}, then search the user's
	# PATH. We do not want to do either if we are running from an
	# uninstalled perl in a perl source tree.
	push @potential, $Config::Config{'perlpath'};

	# ADAMK: This is somewhat dubious, as we could fairly easily
	# accidentally find a different version of Perl, if we
	# are not installed as the first in the PATH (or are not
	# in the PATH at all).
	push @potential, map {
		File::Spec->catfile($_, $name)
	} File::Spec->path;

	# Now that we've enumerated the potential perls, it's time to test
	# them to see if any of them match our configuration, returning the
	# absolute path of the first successful match.
	my %seen  = ();
	my @tried = ();
	my $ext   = $Config::Config{'exe_ext'};
	foreach my $exe ( @potential ) {
		if ( defined $exe and ! $exe =~ m/$ext$/i ) {
			$exe .= $ext;
		}
		next if $seen{$exe};
		return $exe if is($exe);
		push @tried, $exe;
	}

	# We've tried all alternatives, and didn't find a perl that matches
	# our configuration. Throw an exception, and list alternatives we tried.
	my $paths = join( ', ', @tried );
	die "Can't locate the current Perl interpreter (tried $paths)";
}

=pod

=head2 is

  if ( Perl::Exe::is($path) ) {
     print "The Perl interpreter is $path";
  }

The C<Perl::Exe::is> function can be used to take a suspected path and
determine if it is the path to the current Perl interpreter.

Returns true if the path is to the current Perl.

Returns false (but not undef) if there is no file at that path,
of if the interpreter's confifiguration does not match that of
the current Perl.

Because of the file test, any path to perl must contain the
extention (such as .exe) if required on the current platform.

=cut

sub is ($) {
	my $perl = shift;

	# Is it a file that exists
	return '' unless defined $perl;
	return '' unless -f $perl;

	# Fetch the configuration
	my $stdout = '';
	my @cmd    = ( $perl, qw{ -MConfig=myconfig -e print -e myconfig } );
	IPC::Run3::run3( \@cmd, \undef, \$stdout, \undef );

	return $stdout eq Config->myconfig;
}

=pod

=head2 run3

  # Launch a CPAN shell for the current Perl
  Perl::Exe::run3( '-MCPAN -e shell' );
  
  # Capture some generated content
  my $stdout = '';
  Perl::Exe::run3(
      [ '-e', 'print "Hello World!\n";' ],
      undef,    # Inherit STDIN
      \$stdout, # Capture STDOUT
      \undef,   # Discard STDERR
  );

Because B<Perl::Exe> uses L<IPC::Run3> internally for some functionality,
a C<Perl::Exe::run3> pass-through function is provided as a convenience.

Except for the prepending of the path, this function is otherwise
identical to C<IPC::Run3::run3>.

It takes the same paremeters as C<IPC::Run3::run3> function, prepending
the path to the current Perl (to either the string or ARRAY reference
form of the command) and then hands off to the C<IPC::Run3::run3>,
returning the result.

=cut

sub run3 {
	# Prepend the path path
	my $cmd = shift;
	if ( ref $cmd eq 'ARRAY' ) {
		$cmd = [ find, @$cmd ];
	} elsif ( defined $cmd and ! ref $cmd ) {
		$cmd = find . ' ' . $cmd;
	}

	# Hand off to the real function
	IPC::Run3::run3( $cmd, @_ );
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Adapter>

For other issues, or commercial support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Module::Build>, L<IPC::Run3>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

Some parts copyright Ken Williams 2001 - 2006.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
