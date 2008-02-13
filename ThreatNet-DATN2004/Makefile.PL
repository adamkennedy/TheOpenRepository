use inc::Module::Install;

name          ( 'ThreatNet-DATN2004'        );
abstract      ( 'Proposal: The Decentralised Active Threat Network' );
author        ( 'Adam Kennedy<cpan@ali.as>' );
version_from  ( 'lib/ThreatNet/DATN2004.pm' );
license       ( 'perl'                      );

requires      ( 'perl'           => '5.005' );

build_requires( 'Test::More'     => '0.47'  );
build_requires( 'File::Spec'     => '0.82'  );

auto_install();

&WriteAll;
