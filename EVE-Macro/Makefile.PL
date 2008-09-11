use inc::Module::Install 0.77;

license       'proprietary';
all_from      'lib/EVE/Macro/Object.pm';
requires      'File::Spec'           => 0;
requires      'File::HomeDir'        => 0;
requires      'Params::Util'         => 0;
requires      'Config::Tiny'         => 0;
requires      'Win32::GuiTest'       => 0;
requires      'Win32::Process'       => 0;
requires      'Win32::Process::List' => 0;
requires      'Win32'                => 0;
requires      'Imager::Search'       => '0.90';
test_requires 'Test::More'           => 0;

WriteAll;

