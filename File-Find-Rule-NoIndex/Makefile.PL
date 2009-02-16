use inc::Module::Install 0.79;

all_from      'lib/File/Find/Rule/NoIndex.pm';
requires      'File::Spec'        => '3.27';
requires      'Parse::CPAN::Meta' => '0.04';
requires      'File::Find::Rule'  => '0.30';
test_requires 'Test::More'        => '0.42';

WriteAll;
