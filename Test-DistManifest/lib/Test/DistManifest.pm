# Test::DistManifest
#  Tests that your manifest matches the distribution as it exists.
#
# $Id$
#
# Copyright (C) 2008-2009 by Jonathan Yu <frequency@cpan.org>
#
# This package is distributed with the same licensing terms as Perl itself.
# For additional information, please read the included `LICENSE' file.

package Test::DistManifest;

use strict;
use warnings;
use Carp ();

=head1 NAME

Test::DistManifest - Verify MANIFEST/MANIFEST.SKIP as an author test

=head1 VERSION

Version 1.2.0 ($Id$)

=cut

use version; our $VERSION = qv('1.2.0');

=head1 EXPORTS

By default, this module exports the following functions:

=over

=item * manifest_ok

=back

=cut

# File management commands
use Cwd ();
use File::Spec (); # Portability
use File::Spec::Unix (); # To get UNIX-style paths
use File::Find (); # Traverse the filesystem tree

use Module::Manifest ();
use Test::Builder;

my $test = Test::Builder->new;

my @EXPORTS = (
  'manifest_ok',
);

# These platforms were copied from File::Spec
my %platforms = (
  MacOS   => 1,
  MSWin32 => 1,
  os2     => 1,
  VMS     => 1,
  epoc    => 1,
  NetWare => 1,
  symbian => 1,
  dos     => 1,
  cygwin  => 1,
);

# Looking at other Test modules this seems to be an ad-hoc standard
sub import {
  my ($self, @plan) = @_;
  my $caller = caller;

  {
    ## no critic (ProhibitNoStrict, ProhibitNoisyQuotes)
    no strict 'refs';
    for my $func (@EXPORTS) {
      *{$caller . '::' . $func} = \&{$func};
    }
  }

  $test->exported_to($caller);
  $test->plan(@plan);
  return;
}

=head1 DESCRIPTION

This module provides a simple method of testing that a MANIFEST matches the
distribution.

It tests three things:

=over

=item 1

Everything in B<MANIFEST> exists

=item 2

Everything in the package is listed in B<MANIFEST>, or subsequently matches a
regular expression mask in B<MANIFEST.SKIP>

=item 3

Nothing exists in B<MANIFEST> that also matches a mask in B<MANIFEST.SKIP>,
so as to avoid an unsatisfiable dependency conditions

=back

=head1 SYNOPSIS

  use Test::More;

  eval 'use Test::DistManifest';
  if ($@) {
    plan skip_all => 'Test::DistManifest required to test MANIFEST';
  }

  manifest_ok('MANIFEST', 'MANIFEST.SKIP'); # Default options

  manifest_ok(); # Functionally equivalent to above

=head1 COMPATIBILITY

This module was tested under Perl 5.10.0, using Debian Linux. However, because
it's Pure Perl and doesn't do anything too obscure, it should be compatible
with any version of Perl that supports its prerequisite modules.

If you encounter any problems on a different version or architecture, please
contact the maintainer.

=head1 FUNCTIONS

=head2 manifest_ok( $manifest , $skipfile )

This subroutine checks the manifest list contained in C<$manifest> by using
C<Module::Manifest> to determine the list of files and then checking for the
existence of all such files. Then, it checks if there are any files in the
distribution that were not specified in the C<$manifest> file but do not match
any regular expressions provided in the C<$skipfile> exclusion file.

If your MANIFEST file is generated by C<ExtUtils::MakeMaker> or
C<Module::Build>, then you shouldn't have any problems with these files. It's
just a helpful test to remind you to update these files, using:

  $ make dist # For ExtUtils::MakeMaker
  $ ./Build dist # For Module::Build

=head2 Non-Fatal Errors

By default, errors in the B<MANIFEST> or B<MANIFEST.SKIP> files are treated
as fatal, which really is the purpose of using C<Test::DistManifest> as part
of your author test suite.

In some cases this is not desirable behaviour, such as with the Debian Perl
Group, which runs all tests - including author tests - as part of its module
packaging process. This wreaks havoc because Debian adds its control files
in C<debian/> downstream, and that directory or its files are generally not
in B<MANIFEST.SKIP>.

By setting the environment variable B<MANIFEST_WARN_ONLY> to a true value,
errors will be non-fatal - they show up as diagnostic messages only, but all
tests pass from the perspective of C<Test::Harness>.

This can be used in a test script as:

  $ENV{MANIFEST_WARN_ONLY} = 1;

or from other shell scripts as:

  export MANIFEST_WARN_ONLY=1

Note that parsing errors in each file (B<MANIFEST> and B<MANIFEST.SKIP>) and
circular dependencies will always be considered fatal. The author is not aware
of any other use cases where other behaviour would be useful.

=cut

# It's not the simplest subroutine, but it's still not complex enough nor
# useful enough in its parts to really be refactored.
## no critic(ProhibitExcessComplexity)
sub manifest_ok {
  my $warn_only = $ENV{MANIFEST_WARN_ONLY} || 0;

  my $manifile = shift || 'MANIFEST';
  my $skipfile = shift || 'MANIFEST.SKIP';

  my $root = Cwd::getcwd(); # this is Build.PL's Cwd
  my $manifest = Module::Manifest->new;

  unless ($test->has_plan) {
    $test->plan(tests => 5);
  }

  # Try to parse the MANIFEST and MANIFEST.SKIP files
  eval {
    $manifest->open(manifest => $manifile);
  };
  if ($@) {
    $test->diag($!);
  }
  $test->ok(!$@, 'Parse MANIFEST or equivalent');

  eval {
    $manifest->open(skip     => $skipfile);
  };
  if ($@) {
    $test->diag($!);
  }
  $test->ok(!$@, 'Parse MANIFEST.SKIP or equivalent');

  my @files;
  # Callback function called by File::Find
  my $closure = sub {
    # Trim off the package root to determine the relative path.
    my $path = File::Spec->abs2rel($File::Find::name, $root);

    # Portably deal with different OSes
    if ($platforms{$^O}) { # Check if we are on a non-Unix platform
      # Get path info from File::Spec, split apart
      my (undef, $dir, $file) = File::Spec->splitpath($path);
      my @dir = File::Spec->splitdir($dir);

      # Reconstruct the path in Unix-style
      $dir = File::Spec::Unix->catdir(@dir);
      $path = File::Spec::Unix->catpath(undef, $dir, $file);
    }

    # Test that the path is a file and then make sure it's not skipped
    if (-f $path && !$manifest->skipped($path)) {
      push @files, $path;
    }
    return;
  };

  # Traverse the directory recursively
  File::Find::find({
    wanted            => $closure,
    untaint           => 1,
    no_chdir          => 1,
  }, $root);

  # The two arrays have no duplicates. Thus we loop through them and
  # add the result to a hash.
  my %seen;
  # Allocate buckets for the hash
  keys(%seen) = 2 * scalar(@files);
  foreach my $path (@files, $manifest->files) {
    $seen{$path}++;
  }

  my $flag = 1;
  foreach my $path (@files) {
    # Skip the path if it was seen twice (the expected condition)
    next if ($seen{$path} == 2);

    # Oh no, we have files in @files not in $manifest->files
    if ($flag == 1) {
      $test->diag('Distribution files are missing in MANIFEST:');
      $flag = 0;
    }
    $test->diag($path);
  }
  $test->ok($warn_only || $flag, 'All files are listed in MANIFEST or ' .
    'skipped');

  # Reset the flag and test $manifest->files now
  $flag = 1;
  my @circular = (); # for detecting circular logic
  foreach my $path ($manifest->files) {
    # Skip the path if it was seen twice (the expected condition)
    next if ($seen{$path} == 2);

    # If the file should exist but is passed by MANIFEST.SKIP, we have
    # a strange circular logic condition.
    if ($manifest->skipped($path)) {
      push (@circular, $path);
      next;
    }

    # Oh no, we have files in $manifest->files not in @files
    if ($flag == 1) {
      $test->diag('MANIFEST lists the following missing files:');
      $flag = 0;
    }
    $test->diag($path);
  }
  $test->ok($warn_only || $flag, 'All files listed in MANIFEST exist ' .
    'on disk');

  # Test for circular dependencies
  $flag = (scalar @circular == 0) ? 1 : 0;
  if (not $flag) {
    $test->diag('MANIFEST and MANIFEST.SKIP have circular dependencies:');
    foreach my $path (@circular) {
      $test->diag($path);
    }
  }
  $test->ok($flag, 'No files are in both MANIFEST and MANIFEST.SKIP');

  return;
}

=head1 GUTS

This module internally plans 5 tests:

=over

=item 1

B<MANIFEST> and B<MANIFEST.SKIP> can be parsed by C<Module::Manifest>

=item 2

Check which files exist in the distribution directory that do not match an
existing regular expression in B<MANIFEST.SKIP> and not listed in the
B<MANIFEST> file. These files should either be excluded from the test by
addition of a mask in MANIFEST.SKIP (in the case of temporary development
or test files) or should be included in the MANIFEST.

=item 3

Check which files are specified in B<MANIFEST> but do not exist on the disk.
This usually occurs when one deletes a test or similar script from the
distribution, or accidentally moves it.

=item 4

Check which files are specified in both B<MANIFEST> and B<MANIFEST.SKIP>. This
is clearly an unsatisfiable condition, since the file in question cannot be
expected to be included while also simultaneously ignored.

=back

If you want to run tests on multiple different MANIFEST files, you can simply
pass 'no_plan' to the import function, like so:

  use Test::DistManifest 'no_plan';

  # Multiple tests work properly now
  manifest_ok('MANIFEST', 'MANIFEST.SKIP');
  manifest_ok();
  manifest_ok('MANIFEST.OTHER', 'MANIFEST.SKIP');

I doubt this will be useful to users of this module. However, this is used
internally for testing and it might be helpful to you. You can also plan more
tests, but keep in mind that the idea of "3 internal tests"  may change in the
future.

Example code:

  use Test::DistManifest tests => 5;
  manifest_ok(); # 4 tests
  ok(1, 'is 1 true?');

=head1 AUTHOR

Jonathan Yu E<lt>frequency@cpan.orgE<gt>

=head2 CONTRIBUTORS

Your name here ;-)

=head1 ACKNOWLEDGEMENTS

=over

=item * Thanks to Adam Kennedy E<lt>adamk@cpan.orgE<gt>, developer of
Module::Manifest, which is used in this module.

=item * Thanks to Apocalypse E<lt>apocal@cpan.orgE<gt>, for helping me track
down an obscure bug caused by circular dependencies: when files are expected
by MANIFEST but explictly skipped by MANIFEST.SKIP.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::DistManifest

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Dist-Manifest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Dist-Manifest>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Dist-Manifest>

=item * CPAN Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Dist-Manifest>

=item * CPAN Testing Service (Kwalitee Tests)

L<http://cpants.perl.org/dist/overview/Test-DistManifest>

=item * Test::DistManifest's Subversion repository

L<http://svn.ali.as/cpan/trunk/Test-DistManifest>

=back

=head1 REPOSITORY

You can access the most recent development version of this module at:

L<http://svn.ali.as/cpan/trunk/Test-DistManifest>

If you are a CPAN developer and would like to make modifications to the code
base, please contact Adam Kennedy E<lt>adamk@cpan.orgE<gt>, the repository
administrator. I only ask that you contact me first to discuss the changes you
wish to make to the distribution.

=head1 FEEDBACK

Please send relevant comments, rotten tomatoes and suggestions directly to the
maintainer noted above.

If you have a bug report or feature request, please file them on the CPAN
Request Tracker at L<http://rt.cpan.org>. If you are able to submit your bug
report in the form of failing unit tests, you are B<strongly> encouraged to do
so.

=head1 SEE ALSO

L<Test::CheckManifest>, a module providing similar functionality

=head1 CAVEATS

=head2 KNOWN BUGS

There are no known bugs as of this release.

=head2 LIMITATIONS

=over

=item *

There is currently no way to test a MANIFEST/MANIFEST.SKIP without having the
files actually exist on disk. I am planning for this to change in the future.

=item *

This module has not been tested very thoroughly with Unicode.

=item *

This module does not produce any useful diagnostic messages in terms of how
to correct the situation. Hopefully this will be obvious for anybody using
the module; the emphasis should be on generating helpful error messages.

=back

=head1 LICENSE

Copyright (C) 2008-2009 by Jonathan Yu <frequency@cpan.org>

This package is distributed under the same terms as Perl itself. Please see
the LICENSE file included in this distribution for full details of these
terms.

=head1 DISCLAIMER OF WARRANTY

This software is provided by the copyright holders and contributors "AS IS"
and ANY EXPRESS OR IMPLIED WARRANTIES, including, but not limited to, the
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.

In no event shall the copyright owner or contributors be liable for any
direct, indirect, incidental, special, exemplary or consequential damages
(including, but not limited to, procurement of substitute goods or services;
loss of use, data or profits; or business interruption) however caused and on
any theory of liability, whether in contract, strict liability or tort
(including negligence or otherwise) arising in any way out of the use of this
software, even if advised of the possibility of such damage.

=cut

1;
