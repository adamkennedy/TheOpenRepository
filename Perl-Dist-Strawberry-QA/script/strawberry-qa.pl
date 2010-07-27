#! perl

# Note: DO NOT run this in a previously installed (with the .msi) Strawberry installation.
# Either run this from the .zip, or pack it with PAR::Packer.
# The requirement for 5.012 is really so that Strawberry has relocatability.
# This script can TEST any version of Strawberry.

use 5.012;
use warnings;
use Test::More tests => 16;

use File::List::Object 0.189 qw(); # There is a bug in clone() in previous versions. 
use Archive::Extract qw();
use File::Temp qw();
use File::HomeDir qw();
use File::Spec qw();
use File::Copy::Recursive qw(pathrm);
use File::pushd qw(pushd);
use Getopt::Long qw(GetOptions);
use Carp;

diag(qq{Not all of these tests absolutely need to pass,\nbut you should know WHY they aren't passing before release.});

# 0. Check for a C:\strawberry already.

BAIL_OUT('Strawberry Perl directory already exists.') if -d 'C:\\strawberry\\';

# 1. Get base name.

my $basename = '';
my $options = GetOptions('basename=s' => \$basename ) or BAIL_OUT('No basename was passed in. The POD needs read.');
diag("Testing $basename.*");

# 2. Extract .zip

{
	diag('Extracting .zip file - takes a few minutes.');
	my $zipfile = Archive::Extract->new(archive => $basename . '.zip');
	my $extract_ok = $zipfile->extract(to => 'C:\\strawberry\\');

	ok($extract_ok, '.zip file extracted OK');
}

# 3. Get filelist.

my $ziplist = File::Temp::tempnam( File::Spec->tmpdir(), 'SPQA');
diag($ziplist);
my $command = "cmd.exe /c dir /s/w/b C:\\strawberry\\ > $ziplist";
system($command);

# 4. Delete extracted .zip
{
	diag('Deleting .zip of Strawberry.');
	pushd('C:\\');
	pathrm('strawberry');
}

# 5. Extract .msi

BAIL_OUT('Strawberry Perl directory still exists.') if -d 'C:\\strawberry\\';
my $install_ok = system("msiexec /i ${basename}.msi /passive WIXUI_EXITDIALOGOPTIONALCHECKBOX=0");
diag($install_ok);
ok(0 == $install_ok, '.msi file installed OK');

# 6. Get filelist.

my $msilist = File::Temp::tempnam( File::Spec->tmpdir(), 'SPQA');
system("cmd.exe /c dir /s/w/b C:\\strawberry\\ > $msilist");

# 7. Test for file contents.

my $msilist_obj = File::List::Object->new()->load_file($msilist);
my $ziplist_obj = File::List::Object->new()->load_file($ziplist);
my $not_in_msi = File::List::Object->clone($ziplist_obj)->subtract($msilist_obj);
my $not_in_zip = File::List::Object->clone($msilist_obj)->subtract($ziplist_obj);

ok(0 == $not_in_msi->count(), 'No files in .zip that are not in the .msi');
ok(0 == $not_in_zip->count(), 'No files in .msi that are not in the .zip');

# 8. Test for real neccessary files.

ok(-f 'C:\\strawberry\\c\\bin\\gcc.exe', 'gcc.exe exists.');
ok(-f 'C:\\strawberry\\c\\bin\\dmake.exe', 'dmake.exe exists.');
ok(-f 'C:\\strawberry\\perl\\bin\\perl.exe', 'perl.exe exists.');

# 9. Nothing is in site before modules are installed.

ok(0 == scalar glob('C:\\strawberry\\perl\\site\\bin\\*.*'), 'No files in site\\bin');
ok(0 == scalar glob('C:\\strawberry\\perl\\site\\bin\\*.*'), 'No files in site\\lib');

# 10. Module installation tests.

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
	next if -f catfile( $p, 'dmake.exe' );
	next if -f catfile( $p, 'perl.exe' );

	# Strip any path that contains either unzip or gzip.exe.
	# These two programs cause perl to fail its own tests.
	next if -f catfile( $p, 'unzip.exe' );
	next if -f catfile( $p, 'gzip.exe' );

	push @keep, $p;
} ## end foreach my $p (@path)

{
	push @keep, 'C:\\strawberry\\c\\bin', 'C:\\strawberry\\perl\\bin', 'C:\\strawberry\\perl\\site\\bin';
	local $ENV{PATH} = join q{;}, @keep;

	system("cmd.exe /c C:\\strawberry\\perl\\bin\\cpan.bat Try::Tiny");
	ok(-f 'C:\\strawberry\\perl\\site\\lib\\Try\\Tiny.pm', 'cpan.bat can install a pure-perl module using EU::MM.');

	system("cmd.exe /c C:\\strawberry\\perl\\bin\\cpan.bat Devel::Stacktrace");
	ok(-f 'C:\\strawberry\\perl\\site\\lib\\File\\List\\Object.pm', 'cpan.bat can install a pure-perl module using M::B.');

	system("cmd.exe /c C:\\strawberry\\perl\\bin\\cpan.bat Moose");
	ok(-f 'C:\\strawberry\\perl\\site\\lib\\auto\\Moose\\Moose.dll', 'cpan.bat can install an XS module, with dependencies, that uses EU::MM.');

	system("cmd.exe /c C:\\strawberry\\perl\\bin\\cpanp.bat App::FatPacker");
	ok(-f 'C:\\strawberry\\perl\\site\\lib\\App\\FatPacker.pm', 'cpanp.bat can install a pure-perl module using M::I.');

	system("cmd.exe /c C:\\strawberry\\perl\\bin\\cpanp.bat File::pushd");
	ok(-f 'C:\\strawberry\\perl\\site\\lib\\File\\pushd.pm', 'cpanp.bat can install a pure-perl module, with dependencies, that uses M::B.');
}

# 11. Remove the .msi

my $uninstall_ok = system("msiexec /x ${basename}.msi /passive");
ok(0 == $uninstall_ok, '.msi file uninstalled OK');

# TODO: Check that all files are uninstalled.

__END__

prove -v strawberry-qa.pl :: --basename strawberry-perl-professional-5.10.0.3-alpha-2

