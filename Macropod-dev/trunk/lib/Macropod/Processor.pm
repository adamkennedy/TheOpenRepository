package Macropod::Processor;

use strict;
use warnings;
use Carp qw( confess );
use Data::Dumper;
use Pod::POM;
use Pod::POM::View::Pod;
use Pod::POM::Nodes;

use Module::Pluggable
        require     => 1,
        #instantiate => 'new',
        search_path => 'Macropod::Processor',
        only => qr/^Macropod::Processor::(\w+)$/ ,
        except => 'Macropod::Processor::Plugin',
        sub_name    => 'processors';


local $Pod::POM::DEFAULT_VIEW = 'Pod::POM::View::Pod';

sub new {
  my ($class,%args) = @_;
  $args{parser} ||= Pod::POM->new( warn => 1 , view=>'Pod::POM::View::Pod'  ) ;
  return bless \%args, $class;
}


sub process {
  my ($self,$doc) = @_;
   
  my $pom_parser = $self->{parser}; 
  my $combined;
  $combined .= $_->content for   @{ $doc->pod  };
  my $pod = $pom_parser->parse( $combined );
  return $self->_inflate( $doc, $pod );

}


sub _inflate {
  my ($self,$doc,$pod) = @_;
  my $parser = $self->{parser};
  my @sections;
  my $wrapper = "=head1 MACROPOD (auto discovered)\n\n";
  push @sections , $parser->parse( $wrapper );

  my $requires = "=head2 REQUIRES\n\n"; 
if ( $doc->requires ) {
  while (my ($req,$meta) =  each %{ $doc->requires } ) {
    my $link = "L<$req> ";
    $requires .= $link;
  }
  $requires .= "\n";
  push @sections , $parser->parse( $requires );
}

  my $inherits = "=head2 INHERITS\n\n";

  if ( $doc->inherits ) {
    while ( my ($super,$meta) = each %{ $doc->inherits } ) {
      my $link = "L<$super> ";
      $inherits .= $link;
    }
    $inherits .= "\n";
  }
  push @sections, $parser->parse( $inherits );


if ( $doc->imports ) {
  my $imports = "=head2 IMPORTS\n\n";
  my @im_func;
  my @in_var;
  while ( my ($class,$meta) = each %{ $doc->imports } ) {
    while ( my ($type,$values) = each %$meta ) {
      $imports .= "=over\n\n";
      foreach my $name ( keys %$values ) {
        $imports .= "=item L<$name|$class/$name>\n\n";
      }
      $imports .= "=back\n\n";
    }
  }
  $imports .= "\n";
  push @sections, $parser->parse( $imports );
}

if ( $doc->exports ) {
  my $exports = "=head2 EXPORTS (auto discovered)\n\n";
  my @symbols;
  while ( my ($key,$value) =  each %{ $doc->exports } ) {
    $exports .= "=head3 $key\n\n";
    $exports .= "=over 4\n\n";
    $exports .= "=item L<$_\n\n" for values %$value; 
    $exports .= "=back 4\n";
  }
  $exports .= "\n";
  push @sections, $parser->parse( $exports );
}

if ( $doc->method ) {
  my $methods = "=head2 METHODS (auto discovered)\n\n";
  $methods .= "=over\n\n";
  while ( my ($method,$meta) = each %{ $doc->method } ) {
    # ignore meta for now
    $methods .= "=item $method\n\n";
  }
  $methods .= "=back\n\n";
  push @sections, $parser->parse( $methods );
}

  
  local $Pod::POM::DEFAULT_VIEW = 'Pod::POM::View::Pod';
  my $final = "=pod\n\n";
  $final .=  eval { $_->content } for ( $pod , @sections );
  $final .= "=cut\n\n";

  return \$final;
}

1;
