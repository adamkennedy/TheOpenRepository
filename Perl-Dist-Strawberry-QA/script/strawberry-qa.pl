#! perl

# Note: DO NOT run this in a previously installed (with the .msi) Strawberry installation.
# Either run this from the .zip, or pack it with PAR::Packer.
# The requirement for 5.012 is really so that Strawberry has relocatability.
# This script can TEST any recent version of Strawberry.

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
use List::MoreUtils qw(any);
use Config;

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

# 3. Set out to test.

plan tests => 17;
diag(qq{Not all of these tests absolutely need to pass,\nbut you should know WHY they aren't passing before release.});

# 4. Get base name.

my $basename = '';
my $options = GetOptions('basename=s' => \$basename ) or BAIL_OUT('No basename was passed in. The POD needs read.');
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

__END__

=pod

=head1 SYNOPSIS

This script is probably best run like so: (although it can be run independently of L<prove|prove>)

    prove -v strawberry-qa.pl :: --basename strawberry-perl-professional-5.10.0.3-alpha-2

=cut
