use inc::Module::Install;

all_from      'lib/File/BLOB.pm';
requires      'bytes'          => 0;
requires      'Carp'           => 0;
requires      'File::Basename' => 0;
requires      'IO::File'       => 0;
requires      'Storable'       => '2.16';
requires      'Params::Util'   => '0.10';
requires      'File::Type'     => '0.22';
test_requires 'File::Spec'     => '0.80';
test_requires 'Test::More'     => '0.47';

WriteAll;
