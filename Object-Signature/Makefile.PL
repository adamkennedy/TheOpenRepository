use inc::Module::Install;

name           'Object-Signature';
all_from       'lib/Object/Signature.pm';
requires       'Storable'    => '2.11';
requires       'Digest::MD5' => '2.00';
build_requires 'Test::More'  => '0.47';

WriteAll;
