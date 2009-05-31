use inc::Module::Install 0.79;

all_from       'lib/Perl/Metrics2.pm';
requires       'Time::HiRes'       => '1.9718';
requires       'Time::Elapsed'     => '0.24';
requires       'File::Spec'        => winlike() ? '3.2701' : '0.80';
requires       'File::HomeDir'     => '0.82';
requires       'File::ShareDir'    => '1.00';
requires       'Class::Inspector'  => '1.23';
requires       'Params::Util'      => '0.37';
requires       'ORLite'            => '1.21';
requires       'ORLite::Migrate'   => '0.02';
requires       'CPAN::Mini::Visit' => '0.02';
test_requires  'Test::More'        => '0.42';
install_script 'pm2dist';
install_script 'pm2cache';
install_script 'pm2minicpan';
install_script 'pm2db';
install_share;

WriteAll;
