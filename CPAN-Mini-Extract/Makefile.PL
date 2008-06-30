use inc::Module::Install 0.75;

all_from      'lib/CPAN/Mini/Extract.pm';
requires      'File::Spec'             => '0.80';
requires      'File::Remove'           => '0.34';
requires      'File::Find::Rule'       => '0.30';
requires      'File::Temp'             => 0;
requires      'List::Util'             => '1.15';
requires      'IO::Uncompress::Gunzip' => 0;
requires      'Archive::Tar'           => '1.22';
requires      'Params::Util'           => '0.20';
requires      'CPAN::Mini'             => '0.550';
requires      'URI'                    => 0;
requires      'LWP::Online'            => '0.03';
test_requires 'Test::More'             => '0.47';

WriteAll;
