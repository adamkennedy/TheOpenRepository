use inc::Module::Install;

my $iswindows = 0;
$iswindows = 1 if $^O =~ /win32/i;

name           'Archive-Rar';
all_from       'lib/Archive/Rar.pm';

requires       'Data::Dumper'     => '0';
requires_external_bin 'rar';
if ($iswindows) {
    requires 'Win32::Registry' => '0';
}
build_requires 'Test::Simple'     => '0';

WriteAll;
