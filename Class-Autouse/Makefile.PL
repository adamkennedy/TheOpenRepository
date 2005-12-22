use inc::Module::Install;

name           'Class-Autouse';
abstract       'Run-time class loading on first method call';
all_from       'lib/Class/Autouse.pm';
requires       'Carp'       => 0;
requires       'File::Spec' => '0.80';
requires       'List::Util' => '1.11';
build_requires 'Test::More' => '0.47';

# Out test directories contain valid looking modules.
# Make sure they don't get indexed.
no_index       directory => 't';

auto_install;

WriteAll;
