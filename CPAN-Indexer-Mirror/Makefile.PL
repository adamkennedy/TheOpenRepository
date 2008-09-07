use inc::Module::Install 0.77;

all_from      'lib/CPAN/Indexer/Mirror.pm';
requires      'File::Spec'              => '0.80';
requires      'File::Remove'            => '1.42';
requires      'YAML::Tiny'              => '1.33';
requires      'JSON'                    => '2.00';
requires      'URI'                     => '1.34';
requires      'Parse::CPAN::MirroredBy' => '0.01';
test_requires 'Test::More'              => '0.42';

WriteAll;
