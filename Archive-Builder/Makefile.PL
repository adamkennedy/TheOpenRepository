use inc::Module::Install 0.76;

all_from       'lib/Archive/Builder.pm';
requires       'List::Util'       => '1.15';
requires       'File::Spec'       => '0.80';
requires       'File::Flat'       => '1.00';
requires       'Class::Autouse'   => '1.27';
requires       'Class::Inspector' => '1.12';
requires       'IO::String'       => '1.08';
requires       'IO::Zlib'         => 0;
requires       'Params::Util'     => '0.22';
test_requires  'Test::More'       => '0.47';
test_requires  'Test::ClassAPI'   => '1.02';

# Tar and Zip archives are supported by default
requires       'Archive::Zip'     => '1.18';
requires       'Archive::Tar'     => '1.30';

WriteAll;
