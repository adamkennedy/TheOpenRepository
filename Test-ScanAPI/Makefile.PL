use inc::Module::Install;

name     'Test-ScanAPI';
all_from 'lib/Test/ScanAPI.pm';
requires 'Test::More'             => '0.42';
requires 'Test::Builder'          => '0.78';
requires 'File::Find::Rule'       => 0;
requires 'File::Find::Rule::Perl' => '0.03';

WriteAll;
