package Macropod::Parser;
use vars qw( $VERSION );
use strict;
use warnings;
use Scalar::Util qw( blessed );
use PPI;
use YAML ();
use Macropod::Document;
use Macropod::Signature;
use Macropod::Cache;
use Carp qw( confess carp cluck ); 

use PPI::Dumper;
use Data::Dumper;
use Pod::Simple::Search;
use File::HomeDir;
use Module::Pluggable
	require     => 1,
	#instantiate => 'new',
    search_path => 'Macropod::Parser',
	only => qr/^Macropod::Parser::(\w+)$/ ,
    except => 'Macropod::Parser::Plugin',
	sub_name    => 'parsers';


$VERSION = "0.11_00";


=pod

=head1 NAME

Macropod - the Abominable Snowman to POD


=head1 DESCRIPTION

Attempt to parse perl source (via L<PPI>) and derive meaning from
it. Including but not limited to 

=over

=item 

required modules

=item 

exported symbols

=item 

imported symbols

=item 
 
inherited packages

=back


=head1 METHODS

=head2 new

Create a new macropod parser. 


=head3 OPTIONS

=over

=item cache

Accepts a path to a L<Macropod::Cache> for this parser to use. Alternatively
a prebuilt cache that isa Macropod::Cache
    
=back

=head2 parse

Accepts a module name or a path. Returns a parsed L<Macropod::Document>

=head2 parse_file

Accepts a path. Returns a parsed L<Macropod::Document>

=head2 parse_text

Accepts a SCALAR reference. Returns a L<Macropod::Document> eg:

    my $doc = $parser->parse_text( \'package Foo;' );

=cut


sub new {
	my ($class,%args) = @_;
	
	if (my $cache = delete $args{cache}) { 
	    if ( blessed $cache && $cache->isa('Macropod::Cache') ) {
            $class->warning( 'Using cache ' .  $cache );
	    }
	    else {
            confess "Cache '$cache' does not exist: $!" unless -f $cache;
            $args{cache} = Macropod::Cache->new( dbfile=>$cache );
        }
	}
	
	return bless \%args, $class;
}

sub error {
	warn "->error not implemented";
}

sub warning {
  my ($self,$message) = @_;
  warn __PACKAGE__ . " warning: $message\n";
}

sub parse {
	my ($self,$input) = @_;
	my $name2path = Pod::Simple::Search->find($input);
	unless ($name2path) {
		carp  "Cannot resolve input '$input'" ;
		return;
	}
 	return $self->parse_file( $name2path );
}

sub parse_text {
	my ($self,$text) = @_;
	confess "Only pass text as a scalar reference" 
		unless ( ref $text eq 'SCALAR' );

	my $ppi = PPI::Document->new( $text );
#	$self->{inputfile} = "$text";
#	$self->{signature} = Macropod::Signature->digest( $text );
#	$self->{ppi} = $ppi;

	return $self->_parse( ppi_doc=>$ppi );
}

sub parse_file {
	my ($self,$file) = @_;
	my $ppi  = PPI::Document->new( $file );
	
	unless ( $ppi ) {
		 cluck "PPI cannot parse '$file'";
		 return;
	}

	
#	$self->{inputfile} = $file;
#	$self->{signature} = Macropod::Signature->digest_file( $file );
#	$self->{ppi} = $ppi;

	return $self->_parse( source=>$file , ppi_doc => $ppi );

}

sub _parse {
	my ($self,%args) = @_;
	my $ppi = delete $args{ppi_doc} or confess "_parse requires ppi_doc=>";

	my $doc = Macropod::Document->create(
			source => $args{source} ,
			ppi => $ppi,
	);

	my $first_package = $ppi->find_first('PPI::Statement::Package');
	if ( $first_package ) {
		my $package = $first_package->child(2)->content;
		$doc->title( $package );
	}

    my $pod = $ppi->find( 'PPI::Token::Pod' ) ;
	$doc->pod( $pod ? $pod : [] );
	my $packages = $ppi->find( 'PPI::Statement::Package' );
	$doc->packages( $packages ? @$packages : [] );
	my $includes = $ppi->find( 'PPI::Statement::Include' );
	$doc->includes( $includes ? @$includes : [] );
	my $subs = $ppi->find( 'PPI::Statement::Sub' );
	$doc->subs( $subs ? @$subs : [] ); 


#	my @parsers = sort { $a->run_after ne $b } $self->parsers;
my @parsers = $self->parsers;
	foreach my $plugin_class ( @parsers ) {
                my $plugin = $plugin_class->new( parser=>$self );
		my $success = eval { $plugin->parse( $doc ) };
                warn $@ if $@;
	};
	
	$self->{cache}->store( $doc ) if exists $self->{cache};

	return $doc;
}

sub _chase {
	my ($self,$package) = @_;
	my $class = ref $self;
	if (my $cached = $self->have_cached( name=>$package ) ) {
		my ($name,$data) = each %$cached; #FIXME
		my $doc = eval { my $doc = YAML::Load( $data ) };
		return $doc;
	}
	else {
		my $file = Pod::Simple::Search->find( $package );
		return unless $file;
		my $doc = $self->parse_file( $file );
		return $doc;
	}
}

sub have_cached {
	my ($self,$type,$package) = @_;
	return unless exists $self->{cache};
	my $hit =  $self->{cache}->get($type=>$package);
	#warn "Cache hit for $package - $hit" if $hit;
	return $hit;
}

sub init_cache {
	my ($self,$dbfile) = @_;
	if ( ! defined $dbfile ) 
	{
		my $user_dir = File::HomeDir->my_data( 'Macropod' );
warn 'user dir is ' . $user_dir;
		mkpath( $user_dir ) unless -d $user_dir;
		$dbfile = $user_dir . '/macropod_parser.cache.db'; #FIXME File::Spec
	}
	
	unless ( -f $dbfile ) {
		Macropod::Cache->_bootstrap( $dbfile );
	}

	my $cache = Macropod::Cache->new( dbfile=>$dbfile );
	$self->{cache} = $cache;

}


sub _inherited {
	my ($self,$class) = @_;
	

}

sub to_string {
	my ($self) = shift;
	$self->{expanded_output}
}


sub process {
confess "DEPRECATED";
	my ($self,$doc) = @_;

	my @processors = $self->processors;
	foreach my $plugin ( @processors ) {
		$plugin->process( $doc )
	}
	#$self->process_includes($doc);
	#$self->process_inherits($doc);
	

	if ( exists $self->{cache} ) {
		$self->{cache}->store( 
			$doc
		);
	}

}


sub ppidump ($) {
	my $node = shift;
	PPI::Dumper->new($node)->print;
}


sub expand {
	my ($self,$doc) = @_;
	$self->process($doc) unless $doc->processed;

	# TODO insert somewhere nice...
	my $output;

	if ( $doc->pod ) {
		$output .= "$_" for @{ $doc->pod };
	}

	$output .= sprintf 
		"\n=pod\n\n=begin macropod\n\nsignature: %s\n\n=end macropod\n\n", 
		$doc->signature;

	$output .= $self->apply_macros( 
				$self->_dump_items( $_ , $self->{$_} )
			  )	for qw( exports  );
    $output .= $self->apply_macros(
				$self->_dump_extmethods( imports => $self->{imports} )
			);

	$output .= $self->apply_macros(
		$self->_dump_packages(
			inherits => $self->{inherits},
		)
	);
        $output .= $self->apply_macros(
                $self->_dump_packages(
                        requires => $self->{requires},
                )
        );


	$output .= "\n=cut\n\n";

	$self->{expanded_output} = \$output;
	return \$output;

}

sub apply_macros {
	my ($self , $data ) = @_;
	return sprintf "\n=begin :macropod\n\n%s\n=end :macropod\n\n", $data;
	return $data;		
}
sub _dump_items {
	my ($self,$title,$items) = @_;
	my $output;
	$output .=  sprintf "=head1 %s\n\n=over 1\n\n", uc $title;
	foreach my $item ( @$items  ) {
			$output .= sprintf "=item %s\n\n" , $item;
	}
	$output .= "=back\n\n";

	return $output;	
}

sub _dump_packages {
	my ($self,$title,$packages) = @_;
	my @items;
	push @items, sprintf( "L<%s>", $_ ) for @$packages;
	$self->_dump_items( $title, \@items );
}

sub _dump_extmethods {
	my ($self,$title,$methods) = @_;
	my @items;
	push @items , sprintf( "%s L<%s/%s>", $_->{function} ,  $_->{class} , $_->{function}  ) for @$methods;
	$self->_dump_items( $title, \@items );
	
}





sub process_inherits {
	my ($self,$doc) = @_;
	my $inherits =  $doc->inherits;

	foreach my $class ( @$inherits) {
		my $hook = "_inherits_" . $class;
		#$hook =~ tr/:/_/;
		#warn "testing '$hook'";
		if  ( $self->can( $hook ) ) {
			$self->$hook( $doc , $class );	
		}
	}	


}

1;
