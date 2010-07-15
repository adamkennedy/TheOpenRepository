#! perl

# Note: DO NOT run this in a previously installed (with the .msi) Strawberry installation.
# Either run this from the .zip, or pack it with PAR::Packer.
# The requirement for 5.012 is really so that Strawberry has relocatability.

use 5.012;
use warnings;
use Test::More tests => 14;

use File::List::Object 0.189 qw(); # There is a bug in clone() in previous versions. 
use Archive::Extract qw();
use File::Temp qw();
use File::HomeDir qw();
use File::Spec qw();
use File::Copy::Recursive qw();
use File::pushd qw(pushd);

# 0. Get base name.

# TODO!

# 1. Extract .zip

my $zipfile = Archive::Extract->new(archive => $basename . '.zip');
my $extract_ok = $zipfile->extract(to => 'C:\\strawberry\\');

ok($extract_ok, '.zip file extracted OK');

# 2. Get filelist.

my $ziplist = File::Temp::tempnam( File::Spec->tmpdir(), 'SPQA');
system("command /c dir /s/w/b C:\strawberry\ > $ziplist");

# 3. Delete extracted .zip
{ 
	pushd('C:\\');
	File::Copy::Recursive::pathrm('strawberry');
}

# 4. Extract .msi

my $install_ok = system("msiexec /i ${basename}.msi /passive WIXUI_EXITDIALOGOPTIONALCHECKBOX=0");
ok($install_ok, '.msi file installed OK');

# 5. Get filelist.

my $ziplist = File::Temp::tempnam( File::Spec->tmpdir(), 'SPQA');
system("command /c dir /s/w/b C:\strawberry\ > $ziplist");

# 6. Test for file contents.

my $msilist_obj = File::List::Object->new()->load_file('spmsi.txt');
my $ziplist_obj = File::List::Object->new()->load_file('spzip.txt');
my $not_in_msi = File::List::Object->clone($ziplist_obj)->subtract($msilist_obj);
my $not_in_zip = File::List::Object->clone($msilist_obj)->subtract($ziplist_obj);

ok(0 == $not_in_msi->count(), 'No files in .zip that are not in the .msi');
ok(0 == $not_in_zip->count(), 'No files in .msi that are not in the .zip');

# 7. Test for real neccessary files.

ok(-f 'C:\\strawberry\\c\\bin\\gcc.exe', 'gcc.exe exists.');
ok(-f 'C:\\strawberry\\c\\bin\\dmake.exe', 'dmake.exe exists.');
ok(-f 'C:\\strawberry\\perl\\bin\\perl.exe', 'perl.exe exists.');

# 8. Module installation tests.

system("command /c C:\\strawberry\\perl\\bin\\cpan.bat Try::Tiny");
ok(-f 'C:\\strawberry\\perl\\site\\lib\\Try\\Tiny.pm', 'cpan.bat can install a pure-perl module using EU::MM.');

system("command /c C:\\strawberry\\perl\\bin\\cpan.bat Devel::Stacktrace");
ok(-f 'C:\\strawberry\\perl\\site\\lib\\File\\List\\Object.pm', 'cpan.bat can install a pure-perl module using M::B.');

system("command /c C:\\strawberry\\perl\\bin\\cpan.bat Moose");
ok(-f 'C:\\strawberry\\perl\\site\\lib\\auto\\Moose\\Moose.dll', 'cpan.bat can install an XS module, with dependencies, that uses EU::MM.');

system("command /c C:\\strawberry\\perl\\bin\\cpanp.bat App::FatPacker");
ok(-f 'C:\\strawberry\\perl\\site\\lib\\App\\FatPacker.pm', 'cpanp.bat can install a pure-perl module using M::I.');

system("command /c C:\\strawberry\\perl\\bin\\cpanp.bat File::pushd");
ok(-f 'C:\\strawberry\\perl\\site\\lib\\File\\pushd.pm', 'cpanp.bat can install a pure-perl module, with dependencies, that uses M::B.');

# 9. Remove the .msi

my $uninstall_ok = system("msiexec /x ${basename}.msi /passive");
ok($uninstall_ok, '.msi file uninstalled OK');

# TODO: Check that all files are uninstalled.