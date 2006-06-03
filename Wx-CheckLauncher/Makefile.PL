use inc::Module::Install;

name      'Wx-CheckLauncher';
all_from  'lib/Wx/CheckLauncher.pm';
requires  'File::Spec'      => '0.80';
requires  'File::Which'     => '0.05';
requires  'Wx'              => '0.26';
build_requires 'Test::More' => '0.47';

WriteAll;
