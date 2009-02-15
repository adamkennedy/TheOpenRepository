use inc::Module::Install 0.79;

all_from      'lib/CPAN/WWW/Top100/Generator.pm';
requires      'File::Spec'          => '0.80';
requires      'HTML::Spry::DataSet' => '0.01';
test_requires 'Test::More'          => '0.42';
test_requires 'File::Remove'        => '1.42';

# requires_external_bin 'svn';

WriteAll;
