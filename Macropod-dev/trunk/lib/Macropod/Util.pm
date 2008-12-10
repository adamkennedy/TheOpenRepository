package Macropod::Util;
require Exporter;
@ISA = qw(Exporter);
use vars qw( @EXPORT_OK );
use strict;
use warnings;
use Carp qw( confess );
use Scalar::Util qw( blessed );

@EXPORT_OK = qw( 
  dequote
  dequote_list
  dequote_ppi 
  ppi_find_list

);

our %quote_companion = (
 ')' => '(', 
 '}' => '{',
 ']' => '[',
 '>' => '<',
);

sub dequote_ppi  {
  
}


sub dequote {
  my ($in) = @_;
  my $string;
  if ( blessed $in && $in->can( 'content' ) ) {
    $string = $in->content; 
  }
  else {
    $string = $in;
  }
  my $quote_char = chop($string);
  if ( exists $quote_companion{ $quote_char } ) {
    $quote_char = $quote_companion{ $quote_char };
  }
  my $quote_begin = index( $string, $quote_char );
  if ( $quote_begin == -1 ) {
    confess "Failed to find quotechar=$quote_char in string '$string'" ;
  }
  my $dequoted = substr( $string, $quote_begin+1,  );
  return $dequoted;

}

sub dequote_list {
  my ($string) = @_;
  my $dequoted = dequote( $string );
  my @list = grep { defined $_ && $_ ne '' }
             split /\s+/ , $dequoted;
  return @list;
}

sub ppi_find_list {
  sub {
    my ($doc,$ele) = @_;
    return 1 if (
	$ele->isa( 'PPI::Token::Quote' ) 
	|| $ele->isa( 'PPI::Token::QuoteLike::Words' )
    ) 
  }
}

1;

