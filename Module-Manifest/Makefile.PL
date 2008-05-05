use inc::Module::Install;

name          'Module-Manifest';
all_from      'lib/Module/Manifest.pm';
requires      'Carp'           => 0;
requires      'File::Spec'     => '0.80';
requires      'File::Basename' => 0;
requires      'Params::Util'   => '0.10';
test_requires 'Test::More'     => '0.42';

WriteAll;
