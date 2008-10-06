package Macropod::Parser;
use vars qw( $VERSION );
use strict;
use warnings;
use PPI;
use YAML ();
use Macropod::Signature;
use Macropod::Cache;
use Carp qw( confess ); 
use PPI::Dumper;
use Data::Dumper;
use Pod::Simple::Search;
use File::HomeDir;


$VERSION = 0.11;

our %doc_cache;


use base qw( Class::Accessor );
__PACKAGE__->mk_accessors(
	qw( 
		pod 
		packages 
		includes

		inherits
		requires 
		
		macros 
		ppi output  )
);


=pod

=head1 NAME

Macropod - multilegged documentation monster


=head1 DESCRIPTION

It's not javadoc.





=cut


sub new {
	my ($class,%args) = @_;
	return bless \%args, $class;
}

sub error {
	warn "->error not implemented";
}

sub parse {
	my ($self,$input) = @_;
	my $name2path = Pod::Simple::Search->find($input);
	confess "Cannot resolve input '$input'" unless $name2path;
	$self->{name} = $input;
 	return $self->parse_file( $name2path );
}

sub parse_text {
	my ($self,$text) = @_;
	confess "Only pass text as a scalar reference" 
		unless ( ref $text eq 'SCALAR' );

	my $ppi = PPI::Document->new( $text );
	$self->{inputfile} = "$text";
	$self->{signature} = Macropod::Signature->digest( $text );
	$self->{ppi} = $ppi;

	return $self->_parse;
}

sub parse_file {
	my ($self,$file) = @_;
	my $ppi  = PPI::Document->new( $file );
	$self->{inputfile} = $file;
	$self->{signature} = Macropod::Signature->digest_file( $file );
	confess "PPI cannot parse '$file'" 
		unless $ppi ;
	$self->{ppi} = $ppi;

	return $self->_parse;

}

sub _parse {
	my ($self) = @_;

	my $ppi = $self->{ppi};
	$self->{output} = PPI::Document->new( "" );
	
	my $pods = $ppi->find( 'PPI::Token::Pod' );
	$self->{pods} = $pods;
	my @macros =  grep { $_ =~ /^=macropod/; } @$pods  if $pods;
	$self->{macros} = \@macros;

	$self->{packages} = $ppi->find( 'PPI::Statement::Package' );
	$self->{includes} = $ppi->find( 'PPI::Statement::Include' );
	
	$self->{subs} = $ppi->find( 'PPI::Statement::Sub' );
	# TODO , determine methods vs functions heuristicly  ?

	$self->{inherits} = [] ;

	return $self;
}

sub _chase {
	my ($self,$package) = @_;
	my $class = ref $self;
	if (my $cached = $self->have_cached( $package ) ) {
		my ($name,$data) = each %$cached; #FIXME
		my $doc = YAML::Load( $data );
		die Dumper $cached;
	}
	my $file = Pod::Simple::Search->find( $package );
	return unless $file;
	my $dep = $class->new();
	$dep->parse_file( $file );
	$self->{depends}{$package} =  $dep  ;
	return $dep;
}

sub have_cached {
	my ($self,$package) = @_;
	return unless exists $self->{cache};
	#warn __PACKAGE__ . ' try to fetch cached ' . $package;
	return $self->{cache}->get($package);
}

sub init_cache {
	my ($self) = @_;
	my $user_dir = File::HomeDir->my_data( 'Macropod' );
#warn 'user dir is ' . $user_dir;
	mkpath( $user_dir ) unless -d $user_dir;
	my $dbfile = $user_dir . '/macropod_parser.cache.db'; #FIXME File::Spec

	Macropod::Cache->_bootstrap( $dbfile ) unless -f $dbfile;

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
	my ($self) = @_;

	$self->process_includes;
	$self->process_inherits;

	if ( exists $self->{cache} ) {
		$self->{cache}->store( 
			$self->{name},
			$self->{inputfile},
			$self->{signature},
			$self->macros
		);
	}

}

sub _dequote ($) {
	my $node = shift;
	my @strings = grep !/^q(r|q|w)/ , $node->content =~ /([:\w]+)+/g;

	return @strings;
}

sub ppidump ($) {
	my $node = shift;
	PPI::Dumper->new($node)->print;
}


sub expand {
	my ($self) = @_;
	$self->process unless exists $self->{processed};

	# TODO insert somewhere nice...
	my $output;

	if ( $self->{pods} ) {
		$output .= "$_" for @{ $self->{pods} };
	}

$output .= "\n=pod\n\n=begin macropod\n\nsignature: $self->{signature}\n\n=end macropod\n\n";

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



sub process_includes {
	my $self = shift;
	my $uses_packages =  $self->{includes};
	return unless $uses_packages;
	foreach my $used ( @$uses_packages ) {
		my $class = $used->child(2);
		my $hook = "_uses_" . $class->content;
		$hook =~ tr/:/_/;
		if  ( $self->can( $hook ) ) {
			$self->$hook( $used );	
		}
		elsif( $used->find_any( 'PPI::Token::QuoteLike::Words' ) ) {
			$self->_uses_imports( $class->content, $used );
		}
		else {
			push @{ $self->{requires} }, $class->content;
			#warn "Uncaught include of " . $class->content;
			#warn PPI::Dumper->new( $used )->print;
		}
		$self->_chase( $class->content );
	}	

	$uses_packages;
}

sub process_inherits {
	my ($self) = @_;
	my $inherits =  $self->{inherits};

	foreach my $class ( @$inherits) {
		my $hook = "_inherits_" . $class;
		#$hook =~ tr/:/_/;
		#warn "testing '$hook'";
		if  ( $self->can( $hook ) ) {
			$self->$hook( $class );	
		}
	}	


}

sub _uses_imports {
	my ($self,$class,$statement) = @_;
	my $list = $statement->find_first( 'PPI::Token::QuoteLike::Words' );
	my @imports = map {  {class=>$class, function => $_}  } _dequote $list;
	push @{ $self->{imports} } , @imports;
}

sub _uses_base {
	my $self = shift;
	my $node = shift;
	my $imports = $node->find_first( 'PPI::Token::QuoteLike::Words' );
	my @classes = 
		grep !/^q(r|q|w)/ , $imports =~ /([+-:\w]+)+/g;
	push @{ $self->inherits } ,  @classes;
	


}

sub _uses_Exporter {
	my ($self,$node) = @_;
	my $export_ok = $self->ppi->find_first(
		sub { 
			my $node = $_[1];
			return unless $node->isa('PPI::Statement');
			my $sym = $node->find_first('PPI::Token::Symbol') ;
			return unless $sym;
			return $sym->content eq '@EXPORT_OK'
		}
	);
	return unless $export_ok;
    my $words = $export_ok->find_first( 'PPI::Token::QuoteLike::Words' );
 	my @symbols =  _dequote $words;
	push @{ $self->{exports} } , @symbols;

}

sub _inherits_Class::Accessor {
	my ($self) = @_;
	my $package_calls = $self->{ppi}->find(
		sub { 
			my ($doc,$ele) = @_;
			return
				$ele->isa( 'PPI::Statement' )
				&& $ele->child(0)
				&& $ele->child(0)->isa( 'PPI::Token::Word' )
				&& $ele->child(0)->content eq '__PACKAGE__'
				&& $ele->child(1)
				&& $ele->child(1)->content eq '->'
				&& $ele->child(2)
				&& $ele->child(2)->content =~ /^mk_accessor(?:s)?/;
		}
	);
	return unless $package_calls;

	foreach my $call ( @$package_calls  ) {

		#my $list = $call->find( 'PPI::Token::QuoteLike::Words' ) ;
		my $list = $call->find_first('PPI::Structure::List' );
		next unless $list;
		#warn Dumper $list;
	}

}

sub _uses_vars {
#	warn "use vars uncaught";
}

sub _uses_constant {
#	warn "use constant uncaught";
}

sub _uses_Test::More {};


1;
