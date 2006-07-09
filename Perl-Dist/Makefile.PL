# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name        'Perl-Dist';
author      'David A Golden <dagolden@cpan.org>';
license     'perl';
all_from    'lib/Perl/Dist.pm';

requires    'Archive::Tar'      => 1.29; 
requires    'Archive::Zip'      => 1.16;
requires    'CPAN'              => 0;
requires    'File::Copy::Recursive' => 0.25;
requires    'File::Find::Rule'  => 0.30;
requires    'File::Path'        => 1.08; 
requires    'File::pushd'       => 0.32;
requires    'File::Spec'        => 3.17;
requires    'HTTP::Status'      => 1.28;
requires    'IPC::Run3'         => 0.034;
requires    'LWP::UserAgent'    => 2.033;
requires    'Perl6::Say'        => 0.04;
requires    'Tie::File'         => 0;
requires    'Sub::Exporter'     => 0.966;
requires    'YAML'              => 0.62;

auto_install;
WriteAll;
