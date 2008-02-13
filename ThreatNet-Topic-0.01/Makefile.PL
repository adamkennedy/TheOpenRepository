use inc::Module::Install;

name          ( 'ThreatNet-Topic'           );
abstract      ( 'An object representation of a ThreatNet channel topic' );
author        ( 'Adam Kennedy<cpan@ali.as>' );
version_from  ( 'lib/ThreatNet/Topic.pm'    );
license       ( 'perl'                      );

requires      ( 'perl'           => '5.005' );
requires      ( 'URI'            => '1.26'  );

build_requires( 'Test::More'     => '0.47'  );
build_requires( 'File::Spec'     => '0.82'  );

auto_install();

&WriteAll;
