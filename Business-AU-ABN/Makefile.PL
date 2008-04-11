use strict;
use inc::Module::Install;

name           'Business-AU-ABN';
all_from       'lib/Business/AU/ABN.pm';
requires       'Exporter'     => 0;
requires       'List::Util'   => '1.11';
requires       'Params::Util' => '0.10';
test_requires 'File::Spec'   => '0.80';
test_requires 'Test::More'   => '0.47';

WriteAll;
