use inc::Module::Install 0.77;

all_from      'lib/Perl/Squish.pm';
requires      'PPI'        => '1.200';
test_requires 'Test::More' => '0.47';
test_requires 'File::Spec' => '0.82';

WriteAll;
