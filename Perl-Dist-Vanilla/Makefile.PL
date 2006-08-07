# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name        'Perl-Dist-Vanilla';
author      'David A Golden <dagolden@cpan.org>';
license     'perl';
all_from    'lib/Perl/Dist/Vanilla.pm';

requires    'Perl::Dist::Builder'      => '0.000003'; 

no_index    directory => 'extra';
no_index    directory => 'bin';

WriteAll;
