package Perl::Dist::Strawberry::QA;

use 5.012;
use warnings;
use Test::More;
use File::List::Object 0.189 qw(); # There is a bug in clone() in previous versions. 
use Archive::Extract qw();
use File::Temp qw();
use File::HomeDir qw();
use File::Spec qw();
use File::Path qw(remove_tree);
use IPC::Run3 qw(run3);
use Getopt::Long qw(GetOptions);
use Win32 qw(CSIDL_COMMON_STARTMENU);
use List::MoreUtils 0.22 qw(any);
use Config;
use Exporter::Lite;

our $VERSION = '0.100';
our @EXPORT  = qw(test);

sub test {

	# 1. Check for a C:\strawberry already.

	plan skip_all => 'Not running on Win32 system' if $Config{archname} !~ /Win32/msx;
	plan skip_all => 'Strawberry Perl default directory already exists.' if -d 'C:\\strawberry\\';

	# 2. Check for start menu options (as a test for the .msi being installed.)
	
	my $startmenu = Win32::GetFolderPath(CSIDL_COMMON_STARTMENU);
	$startmenu .= "\\*";
	my @startmenu = glob $startmenu;
	plan skip_all => <<'MSI_INSTALLED' if any { m/Strawberry[ ]Perl/msx } @startmenu;
We have start menu options for Strawberry. The .msi is probably installed, so not a good idea to run the QA tests and fail without testing anything.
MSI_INSTALLED

	# 3. Get base name.

	my $basename;
	my $options = GetOptions('basename=s' => \$basename );
	if ((not $options) or (not defined $basename) or ($basename eq q{})) {
		$basename = $ENV{'PERL_DIST_STRAWBERRY_QA_BASENAME'};
		if ((defined $basename) and ($basename ne q{})) {
			$options = 1;
		} else {
			$options = 0;
		}
	}
	if (not $options) {
		plan skip_all => 'No basename parameter was passed in. Read the documentation for how to do so.';
	}
	
	# 4. Set out to test.

	plan tests => 17;
	diag(qq{Not all of these tests absolutely need to pass,\nbut you should know WHY they aren't passing before release.});
	diag("Testing $basename.*");

	# 5. Extract .zip

	{
		diag('Extracting .zip file - takes a few minutes.');
		my $zipfile = Archive::Extract->new(archive => $basename . '.zip');
		my $extract_ok = $zipfile->extract(to => 'C:\\strawberry\\');

		ok($extract_ok, '.zip file extracted OK');
	}

	# 6. Get filelist.

	my $ziplist = File::Temp::tempnam( File::Spec->tmpdir(), 'SPQA');
	my $command = "cmd.exe /c dir /s/w/b C:\\strawberry\\ > $ziplist";
	system($command);

	# 7. Delete extracted .zip
	diag('Deleting .zip of Strawberry.');
	remove_tree('C:\\strawberry\\');

	# 8. Install .msi

	BAIL_OUT('Strawberry Perl directory still exists.') if -d 'C:\\strawberry\\';
	my $install_ok = system("msiexec /i ${basename}.msi /passive WIXUI_EXITDIALOGOPTIONALCHECKBOX=0");
	ok(0 == $install_ok, '.msi file installed OK');

	# 9. Get filelist.

	my $msilist = File::Temp::tempnam( File::Spec->tmpdir(), 'SPQA');
	system("cmd.exe /c dir /s/w/b C:\\strawberry\\ > $msilist");

	# 10. Test for file contents.

	my $msilist_obj = File::List::Object->new()->load_file($msilist);
	my $ziplist_obj = File::List::Object->new()->load_file($ziplist);
	my $not_in_msi = File::List::Object->clone($ziplist_obj)->subtract($msilist_obj);
	my $not_in_zip = File::List::Object->clone($msilist_obj)->subtract($ziplist_obj);

	ok(0 == $not_in_msi->count(), 'No files in .zip that are not in the .msi') or diag("Not in .msi file:\n" . $not_in_msi->as_string());
	ok(0 == $not_in_zip->count(), 'No files in .msi that are not in the .zip') or diag("Not in .zip file:\n" . $not_in_zip->as_string());

	# 11. Test for real neccessary files.

	ok(-f 'C:\\strawberry\\c\\bin\\gcc.exe', 'gcc.exe exists.');
	ok(-f 'C:\\strawberry\\c\\bin\\dmake.exe', 'dmake.exe exists.');
	ok(-f 'C:\\strawberry\\perl\\bin\\perl.exe', 'perl.exe exists.');

	# 12. Nothing is in site before modules are installed.

	my @sitebin = glob 'C:\\strawberry\\perl\\site\\bin\\*.*';
	my $sitebin_size = $#sitebin + 1;
	ok(0 == $sitebin_size , 'No files in site\\bin') or diag(join "\n", "In site//bin: ${sitebin_size} file(s)", @sitebin);

	my @sitelib = glob 'C:\\strawberry\\perl\\site\\lib\\*.*';
	my $sitelib_size = $#sitelib + 1;
	ok(0 ==  $sitelib_size, 'No files in site\\lib') or diag(join "\n", "In site//lib: ${sitelib_size} file(s)", @sitelib);

	# 13. Module installation tests.

	# Remove any Perl installs from PATH to prevent
	# "which" discovering stuff it shouldn't.
	my @path = split /;/ms, $ENV{PATH};
	my @keep = ();
	foreach my $p (@path) {

		# Strip any path that doesn't exist
		next unless -d $p;

		# Strip any path that contains either dmake or perl.exe.
		# This should remove both the ...\c\bin and ...\perl\bin
		# parts of the paths that Vanilla/Strawberry added.
		next if -f File::Spec->catfile( $p, 'dmake.exe' );
		next if -f File::Spec->catfile( $p, 'perl.exe' );

		# Strip any path that contains either unzip or gzip.exe.
		# These two programs cause perl to fail its own tests.
		next if -f File::Spec->catfile( $p, 'unzip.exe' );
		next if -f File::Spec->catfile( $p, 'gzip.exe' );

		push @keep, $p;
	} ## end foreach my $p (@path)

	my @install_tests = (
	[
		[qw(cmd.exe /c C:\\strawberry\\perl\\bin\\cpan.bat Try::Tiny)],
		'C:\\strawberry\\perl\\site\\lib\\Try\\Tiny.pm',
		'cpan.bat can install a pure-perl module that uses ExtUtils::MakeMaker.',
	], 
	[
		[qw(cmd.exe /c C:\\strawberry\\perl\\bin\\cpan.bat Devel::StackTrace)],
		'C:\\strawberry\\perl\\site\\lib\\Devel\\StackTrace.pm',
		'cpan.bat can install a pure-perl module using Module::Build.',
	], 
	[
		[qw(cmd.exe /c C:\\strawberry\\perl\\bin\\cpan.bat Moose)],
		'C:\\strawberry\\perl\\site\\lib\\auto\\Moose\\Moose.dll', # This is deliberately the .dll.
		'cpan.bat can install an XS module, with dependencies, that uses ExtUtils::MakeMaker.',
	], 
	[
		[qw(cmd.exe /c C:\\strawberry\\perl\\bin\\cpanp.bat i App::FatPacker)],
		'C:\\strawberry\\perl\\site\\lib\\App\\FatPacker.pm',
		'cpanp.bat can install a pure-perl module using Module::Install.',
	], 
	[
		[qw(cmd.exe /c C:\\strawberry\\perl\\bin\\cpanp.bat i File::pushd)],
		'C:\\strawberry\\perl\\site\\lib\\File\\pushd.pm',
		'cpanp.bat can install a pure-perl module, with dependencies, that uses Module::Build.',
	], 
	);

	{
		push @keep, 'C:\\strawberry\\c\\bin', 'C:\\strawberry\\perl\\bin', 'C:\\strawberry\\perl\\site\\bin';
		local $ENV{PATH} = join q{;}, @keep;
		
		my $output;

		foreach my $install_test (@install_tests) {
			run3($install_test->[0], \undef, \$output, \$output, {return_if_system_error => 1});
			ok(-f $install_test->[1], $install_test->[2]) or note($output);
		}	
	}

	# 14. Remove the .msi.

	my $uninstall_ok = system("msiexec /x ${basename}.msi /passive");
	ok(0 == $uninstall_ok, '.msi file uninstalled OK');
	ok(! -d 'C:\\strawberry\\', 'No Strawberry directory left over.'); 
	ok(! -d 'C:\\cpanplus\\', 'No cpanplus directory left over.'); 

	return;
}

1;

__END__

=pod

=begin readme text

Perl::Dist::Strawberry::QA version 0.100

=end readme

=for readme stop

=head1 NAME

Perl::Dist::Strawberry::QA - Quality assurance for Strawberry-based Perl distributions.

=head1 VERSION

This document describes Perl::Dist::Strawberry::QA version 0.100.

=for readme continue

=head1 DESCRIPTION

TODO

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=end readme

=for readme stop

=head1 SYNOPSIS

	# Note that the .zip and the .msi have to be in the same directory.
	C:\> perl -MPerl::Dist::Strawberry::QA -e test --basename C:\dl\strawberry-perl-5.12.1.0

=head1 INTERFACE

The module exports one routine, called C<test>, which executes all the 
"quality assurance" tests for Strawberry Perl.

Either the --basename option must be on the command line, or the 
C<PERL_DIST_STRAWBERRY_QA_BASENAME> environment variable must be set,
so that the tests know what Strawberry Perl installation files they are
supposed to be testing.
	
=head1 DIAGNOSTICS

This distribution is meant to be used as a test, so all diagnostics are 
returned as failing tests or skipped tests.

=head1 CONFIGURATION AND ENVIRONMENT

Perl::Dist::Strawberry::QA requires no configuration files or environment 
variables as of yet.

An optional environment variable, PERL_DIST_STRAWBERRY_QA_BASENAME, can be 
used in order to be able to omit the --basename parameter.

=for readme continue

=head1 DEPENDENCIES

Dependencies of this module that are non-core in perl 5.12.0 (which is the 
minimum version of Perl required) include 
L<File::List::Object|File::List::Object> version 0.189, 
L<Archive::Extract|Archive::Extract>, L<File::HomeDir|File::HomeDir>, 
L<IPC::Run3|IPC::Run3>, L<Exporter::Lite|Exporter::Lite>, 
and L<List::MoreUtils|List::MoreUtils> version 0.22.

=for readme stop

=head1 INCOMPATIBILITIES

This module is incompatible with any normal .msi installation of Strawberry 
Perl, because the .msi cannot be installed twice.

This module is also incompatible with any perl installed in C:\strawberry\, 
because that directory needs to be empty in order to be installed to twice.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs and suggestions for improvement should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Strawberry-QA>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-Strawberry-QA@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHOR

Curtis Jewell, C<< <csjewell@cpan.org> >>

=head1 SEE ALSO

L<http://csjewell.comyr.com/perl/>

=for readme continue

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Curtis Jewell C<< <csjewell@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.12.0 or any later version. See L<perlartistic> and L<perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=for readme stop

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
