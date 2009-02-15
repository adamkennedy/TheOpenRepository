use inc::Module::Install 0.79;

all_from      'lib/CPAN/WWW/Top100/Generator.pm';
requires      'File::Spec'          => '0.80';
requires      'HTML::Spry::DataSet' => '0.01';
requires      'CPANTS::Weight'      => '0.02';
test_requires 'Test::More'          => '0.42';
test_requires 'File::Remove'        => '1.42';

WriteAll;
