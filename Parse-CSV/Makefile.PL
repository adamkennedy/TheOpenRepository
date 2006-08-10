use inc::Module::Install;

name           'Parse-CSV';
all_from       'lib/Parse/CSV.pm';
requires       'Carp'         => 0;
requires       'IO::File'     => 0;
requires       'Text::CSV_XS' => '0.23';
requires       'Params::Util' => '0.17';
build_requires 'File::Spec'   => '0.80';
build_requires 'Test::More'   => '0.47';

WriteAll;
