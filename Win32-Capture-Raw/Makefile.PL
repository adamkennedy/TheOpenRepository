use inc::Module::Install 0.77;

all_from      'lib/Win32/Capture/RAW.pm';
requires      'Exporter'   => 0;
requires      'Win32::API' => 0;
test_requires 'Test::More' => '0.42';

WriteAll;
