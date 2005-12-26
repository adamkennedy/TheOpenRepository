use inc::Module::Install;

name           'Object-Signature';
all_from       'lib/Object/Signature.pm';
requires       'Storable'        => '2.11';
requires       'Digest::MD5'     => '2.00';
build_requires 'Test::More'      => '0.47';
build_requires 'File::Spec'      => '0.80';

auto_install;
WriteAll;
