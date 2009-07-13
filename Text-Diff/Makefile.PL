use ExtUtils::MakeMaker;

use strict ;

WriteMakefile(
    'NAME'          => 'Text::Diff',
    'VERSION_FROM'  => 'lib/Text/Diff.pm',
    'PREREQ_PM'     => {
        'Algorithm::Diff'  => 0,
    },
);

sub MY::libscan {
   package MY ;
   my $self = shift ;
   my ( $path ) = @_ ;
   return '' if /\.sw[a-z]$/ ;
   return '' unless length $self->SUPER::libscan( $path ) ;
   return $path ;
}
