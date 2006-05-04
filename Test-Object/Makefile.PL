use inc::Module::Install;

name     'Test-Object';
all_from 'lib/Test/Object.pm';
requires 'Carp'         => 0;
requires 'overload'     => 0;
requires 'Scalar::Util' => '1.16';
requires 'Test::More'   => '0.47';
requires 'File::Spec'   => '0.80';

auto_install;
WriteAll;
