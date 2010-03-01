use inc::Module::Install 0.94;

license        'perl';
version_from   'lib/App/local/lib/Win32Helper.pm';
requires       'local::lib'            => 1.004007;
requires       'IO::Interactive'       => 0.000005;
requires       'File::HomeDir'         => 0.81;
requires       'File::Spec::Functions' => 3.2701;
requires       'Win32::TieRegistry'    => 0.26;
test_requires  'Test::More'            => 0.42;
install_script 'llw32helper.pl';
use_ptar;
