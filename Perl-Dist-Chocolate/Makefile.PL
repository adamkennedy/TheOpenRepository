use inc::Module::Install 0.76;

all_from 'lib/Perl/Dist/Chocolate.pm';
requires 'Perl::Dist::Strawberry' => '1.04';

WriteAll;
