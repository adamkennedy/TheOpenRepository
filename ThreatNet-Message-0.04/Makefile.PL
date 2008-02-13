use inc::Module::Install;

name          ( 'ThreatNet-Message'         );
abstract      ( 'An object representation of a ThreatNet channel message' );
author        ( 'Adam Kennedy<cpan@ali.as>' );
version_from  ( 'lib/ThreatNet/Message.pm'  );
license       ( 'perl'                      );

requires      ( 'perl'           => '5.005' );
requires      ( 'Net::IP'        => '0'     );

build_requires( 'Test::More'     => '0.47'  );
build_requires( 'File::Spec'     => '0.82'  );

auto_install();

&WriteAll;
