use strict;
use inc::Module::Install;

name           'File-BLOB';
all_from       'lib/File/BLOB.pm';
requires       'bytes'          => 0;
requires       'Carp'           => 0;
requires       'File::Basename' => 0;
requires       'Storable'       => 0;
requires       'Params::Util'   => '0.10';
requires       'File::Type'     => 0;
test_requires 'File::Spec'     => '0.80';
test_requires 'Test::More'     => '0.47';

WriteAll;
