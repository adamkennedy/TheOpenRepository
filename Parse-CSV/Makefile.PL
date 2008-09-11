use inc::Module::Install;

name          'Parse-CSV';
all_from      'lib/Parse/CSV.pm';
requires      'Carp'         => 0;
requires      'IO::File'     => 0;
requires      'Text::CSV_XS' => '0.42';
requires      'Params::Util' => '0.17';
test_requires 'File::Spec'   => '0.80';
test_requires 'Test::More'   => '0.47';

WriteAll;
