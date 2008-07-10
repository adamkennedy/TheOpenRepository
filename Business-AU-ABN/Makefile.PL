use inc::Module::Install 0.76;

all_from      'lib/Business/AU/ABN.pm';
requires      'constant'     => 0;
requires      'overload'     => 0;
requires      'Exporter'     => 0;
requires      'List::Util'   => '1.11';
requires      'Params::Util' => '0.25';
test_requires 'File::Spec'   => '0.80';
test_requires 'Test::More'   => '0.47';

WriteAll;
