use strict;
use inc::Module::Install;

name          ( 'Image-Delivery'                     );
abstract      ( 'Sophisticated ultra-efficient delivery of generated website images' );
author        ( 'Adam Kennedy<cpan@ali.as>'          );
version_from  ( 'lib/Image/Delivery.pm'              );
license       ( 'perl'                               );
requires      ( 'perl'                  => '5.005'   );
requires      ( 'File::Spec'            => '0.80'    );
requires      ( 'IO::Handle'            => 0         );
requires      ( 'Digest::MD5'           => 0         );
requires      ( 'File::Remove'          => '0.20'    ); # Change to the current version
requires      ( 'File::Slurp'           => '9999.04' );
requires      ( 'List::Util'            => '1.11'    );
requires      ( 'HTML::Location'        => '1.00'    );
requires      ( 'Digest::TransformPath' => '0.01'    );
requires      ( 'Params::Coerce'        => '0.13'    );
build_requires( 'Test::More'            => '0.47'    );
build_requires( 'IO::File'              => 0         );
auto_install  (                                      );

&WriteAll;
