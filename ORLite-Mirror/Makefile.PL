use inc::Module::Install 0.79;

all_from      'lib/ORLite/Mirror.pm';
requires      'File::Spec'              => winlike() ? '3.2701' : '0.80';
requires      'File::Path'              => '2.04';
requires      'File::HomeDir'           => '0.69';
requires      'File::Remove'            => '1.40';
requires      'Params::Util'            => '0.33';
requires      'URI'                     => '1.35';
requires      'LWP'                     => '5.806';
requires      'LWP::Online'             => '1.07';
requires      'ORLite'                  => '1.19';
requires      'IO::Uncompress::Gunzip'  => '2.008';
requires      'IO::Uncompress::Bunzip2' => '2.008';
test_requires 'Test::More'              => '0.47';
test_requires 'IO::Compress::Gzip'      => '2.008';
test_requires 'IO::Compress::Bzip2'     => '2.008';

WriteAll;
