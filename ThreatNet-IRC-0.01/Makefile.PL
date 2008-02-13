use inc::Module::Install;

name          ( 'ThreatNet-IRC'                  );
abstract      ( 'ThreatNet IRC-specific classes' );
author        ( 'Adam Kennedy <cpan@ali.as>'     );
version_from  ( 'lib/ThreatNet/IRC.pm'           );
license       ( 'perl'                           );

requires      ( 'perl'                => '5.005' );
requires      ( 'Params::Util'        => '0.01'  );
requires      ( 'ThreatNet::Message'  => '0.01'  );

build_requires( 'Test::More'          => '0.47'  );
build_requires( 'File::Spec'          => '0.82'  );

auto_install();

&WriteAll;
