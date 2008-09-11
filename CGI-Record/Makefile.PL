use inc::Module::Install;

name          'CGI-Record';
all_from      'lib/CGI/Record.pm';
requires      'CGI::Capture'        => '1.09';
requires      'DBI'                 => 0;
requires      'DBD::SQLite'         => 0;
test_requires 'Test::More'          => '0.42';
test_requires 'Test::File::Cleaner' => 0;

WriteAll;
