use inc::Module::Install;

name          ( 'ThreatNet-Filter'              );
abstract      ( 'The ThreatNet message filtering API' );
author        ( 'Adam Kennedy<cpan@ali.as>'     );
version_from  ( 'lib/ThreatNet/Filter.pm'       );
license       ( 'perl'                          );

requires      ( 'perl'               => '5.005' );
requires      ( 'Params::Util'       => '0.04'  );
requires      ( 'Net::IP::Match::XS' => '0.03'  );
requires      ( 'ThreatNet::Message' => '0.04'  );

build_requires( 'Test::More'         => '0.47'  );
build_requires( 'File::Spec'         => '0.82'  );

auto_install();

&WriteAll;
