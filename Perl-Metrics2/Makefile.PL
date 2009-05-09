use inc::Module::Install 0.79;

all_from      'lib/Perl/Metrics2.pm';
requires      'File::Spec'       => winlike() ? '3.2701' : '0.80';
requires      'File::HomeDir'    => '0.82';
requires      'File::ShareDir'   => '1.00';
requires      'Class::Inspector' => '1.23';
requires      'Params::Util'     => '0.37';
requires      'ORLite'           => '1.20';
requires      'ORLite::Migrate'  => '0.02';
test_requires 'Test::More'       => '0.42';
install_script 'pm2dist';
install_share;

WriteAll;
