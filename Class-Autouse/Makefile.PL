use inc::Module::Install;

name           'Class-Autouse';
all_from       'lib/Class/Autouse.pm';
requires       'Carp'       => 0;
requires       'base'       => 0;
requires       'File::Spec' => '0.80';
if ( $^O eq 'Win32' or $^O eq 'cygwin' ) {
    # 1.18 known to not work on Win32
    requires   'List::Util' => '1.17';
} else {
    # Strongly encourage upgrading to remove
    # memory leak.
    requires   'List::Util' => '1.18';
}
build_requires 'Test::More' => '0.47';

auto_install;
WriteAll;
