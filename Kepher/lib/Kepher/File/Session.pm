package Kepher::File::Session;

use strict;
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.11';
}

# extern
sub load {
	my $file_name = Kepher::Dialog::get_file_open(
		Kepher::App::Window::_get(),
		$Kepher::localisation{'dialog'}{'file'}{'open_session'},
		$Kepher::config{'file'}{'current'}{'session'}{'directory'},
		$Kepher::internal{'file'}{'filterstring'}{'config'}
	);
	if ( -r $file_name ) {
		my %temp_config = %{ Kepher::Config::File::load($file_name) };
		if (%temp_config) {
			Kepher::File::close_all();
			my $start_node = $Kepher::config{'file'}{'current'}{'session'}{'node'};
			my @load_files = @{ Kepher::Config::_convert_node_2_AoH(
					\$temp_config{$start_node}{'open'}
			) };
			my $start_file_nr = $temp_config{$start_node}{'current_nr'};
			@load_files = @{ &_forget_gone_files( \@load_files ) };

			# open remembered files with all properties
			Kepher::Document::Internal::restore( \%{ $load_files[$_] } )
				for ( 0 .. $#load_files );

			# how many buffer we currently have and save the last doc?
			my $buffer = $Kepher::internal{'document'}{'buffer'};
			Kepher::Document::Internal::eval_properties($buffer-1);

			# slecting starting doc
			$start_file_nr = 0
				if (not defined $start_file_nr) or ($start_file_nr < 0 );
			$start_file_nr = $buffer - 1 if $start_file_nr >= $buffer ;

			# activate the starting document & some afterwork
			Kepher::Document::Change::to_number($start_file_nr);
			Kepher::Document::_set_previous_nr($start_file_nr);
			_remember_directory($file_name);
		} else {
			Kepher::Dialog::warning_box(undef, $file_name,
			    $Kepher::localisation{'dialog'}{'error'}{'config_parse'});
		}
	}
}

sub add {
	my $file_name = Kepher::Dialog::get_file_open(
		Kepher::App::Window::_get(),
		$Kepher::localisation{'dialog'}{'file'}{'add_session'},
		$Kepher::config{'file'}{'current'}{'session'}{'directory'},
		$Kepher::internal{'file'}{'filterstring'}{'config'}
	);
	if ( -r $file_name ) {
		my %temp_config = %{ Kepher::Config::File::load($file_name) };
		if (%temp_config) {
			my $current_doc_nr = $Kepher::document{'current_nr'};
			my $prev_doc_nr    = $Kepher::document{'previous_nr'};
			my $start_node
				= $Kepher::config{'file'}{'current'}{'session'}{'node'};
			my @load_files = @{ Kepher::Config::_convert_node_2_AoH(
					\$temp_config{$start_node}{'open'}
			) };
			@load_files = @{ _forget_gone_files( \@load_files ) };

			# open remembered files with all properties
			Kepher::Document::Internal::save_properties($current_doc_nr);
			Kepher::Document::Internal::restore( \%{ $load_files[$_] } )
				for ( 0 .. $#load_files );

			# make file history like before
			Kepher::Document::Internal::change_pointer($current_doc_nr);
			Kepher::Document::Internal::eval_properties($current_doc_nr);
			_remember_directory($file_name);
		} else {
			Kepher::Dialog::warning_box(undef, $file_name,
			    $Kepher::localisation{'dialog'}{'error'}{'config_parse'});
		}
	}
}

sub save {
	my $config_file = shift;
	$config_file = $Kepher::internal{path}{config}
		. $Kepher::config{'file'}{'current'}{'session'}{'file'}
		unless $config_file;
	my $start_node = shift;
	$start_node = $Kepher::config{'file'}{'current'}{'session'}{'node'}
		unless $start_node;
	my %temp_config;
	%temp_config = %{ &Kepher::Config::File::load($config_file) }
		if ( -r $config_file );
	undef $temp_config{$start_node}{'open'};
	&Kepher::Config::_convert_node_2_AoH( \$Kepher::document{'open'} );
	@{ $Kepher::document{'open'} }
		= @{ _forget_gone_files( \$Kepher::document{'open'} ) };
	@{ $temp_config{$start_node}{'open'} } = @{ $Kepher::document{'open'} };
	$temp_config{$start_node}{'current_nr'} = $Kepher::document{'current_nr'};
	Kepher::Config::File::store( $config_file, \%temp_config );
}

sub save_as {
	my $file_name = Kepher::Dialog::get_file_save( Kepher::App::Window::_get(),
		$Kepher::localisation{'dialog'}{'file'}{'save_session'},
		$Kepher::config{'file'}{'current'}{'session'}{'directory'},
		$Kepher::internal{'file'}{'filterstring'}{'config'}
	);
	if ( length($file_name) > 0 ) {
		&save( $file_name, "files" );
		_remember_directory($file_name);
	}
}

sub import_scite {
	my $win = Kepher::App::Window::_get();
	my $file_name = Kepher::Dialog::get_file_open( $win,
		$Kepher::localisation{'dialog'}{'file'}{'open_session'},
		$Kepher::internal{'path'}{'config'},
		$Kepher::internal{'file'}{'filterstring'}{'scite'}
	);
	if ( -r $file_name ) {
		if ( open my $FILE, "<$file_name" ) {
			my @load_files;
			my ( $start_file_nr, $file_nr );
			while (<$FILE>) {
				m/<pos=(-?)(\d+)> (.+)/;
				if ( -e $3 ) {
					$start_file_nr = $file_nr if $1;
					$load_files[$file_nr]{'cursorpos'} = $2;
					$load_files[$file_nr++]{'path'}    = $3;
				}
			}
			if (@load_files) {
				&Kepher::File::close_all;
				for (@load_files) {
					Kepher::Document::Internal::add( ${$_}{'path'} );
					Kepher::Edit::_goto_pos( ${$_}{'cursorpos'} );
				}
				Kepher::Document::Change::to_number($start_file_nr);
				$Kepher::document{'previous_nr'} = $start_file_nr;
			} else {
				Kepher::Dialog::warning_box( $win, $file_name,
					$Kepher::localisation{'dialog'}{'error'}{'config_parse'} );
			}
		} else {
			my $err_msg = $Kepher::localisation{'dialog'}{'error'};
			Kepher::Dialog::warning_box 
				($win, $err_msg->{file_read}." $file_name", $err_msg->{file});
		}
	}
}

sub export_scite {
	my $win = Kepher::App::Window::_get();
	my $file_name = Kepher::Dialog::get_file_save( $win,
		$Kepher::localisation{'dialog'}{'file'}{'save_session'},
		$Kepher::internal{'path'}{'config'},
		$Kepher::internal{'file'}{'filterstring'}{'scite'}
	);
	if ( length($file_name) > 0 ) {
		if ( open my $FILE, ">$file_name" ) {
			my ( $current, $output ) = ( $Kepher::document{'current_nr'}, );
			for ( 0 .. Kepher::Document::_get_last_nr() ) {
				my %file = %{ $Kepher::document{'open'}[$_] };
				if ( -e $file{'path'} ) {
					$output .= "<pos=";
					$output .= "-" if $_ == $current;
					$output .= "$file{cursorpos}> $file{path}\n";
				}
			}
			print $FILE $output;
		} else {
			my $err_msg = $Kepher::localisation{'dialog'}{'error'};
			Kepher::Dialog::warning_box
				($win, $err_msg->{file_write}." $file_name", $err_msg->{file} );
		}
	}
}

# default session handling
sub store {
	my $config = $Kepher::config{'file'}{'current'}{'session'};
	if ( $config->{'save'} eq 'extern' ) {
		save( Kepher::Config::filepath( $config->{file} ) );
	}
}

sub restore {
	my $config = $Kepher::config{'file'}{'current'}{'session'};
	my $intern = $Kepher::internal{'document'};
	my @load_files;
	my $start_file_nr = $Kepher::document{'current_nr'};
	$start_file_nr ||= 0;
	$Kepher::document{'current_nr'} = 0;
	$Kepher::internal{'document'}{'changed'}= 0;
	$Kepher::internal{'document'}{'loaded'} = 0;

	# detect wich files to load
	if ( $config->{'save'} eq 'not' ) {
		# Do nothing

	} elsif ( $config->{'save'} eq 'intern' ) {
		@load_files = @{ Kepher::Config::_convert_node_2_AoH( \$Kepher::document{open} ) };

	} elsif ( $config->{'save'} eq 'extern' ) {
		my $file_name   = Kepher::Config::filepath( $config->{file} );
		my $start_node  = $config->{'node'};
		my %temp_config = %{ Kepher::Config::File::load($file_name) };
		@load_files = @{
			Kepher::Config::_convert_node_2_AoH( \$temp_config{$start_node}{'open'} )
		};
		$start_file_nr = $temp_config{$start_node}{'current_nr'};
	}

	# afterwork
	undef $Kepher::document{'open'};
	@load_files = @{ &_forget_gone_files( \@load_files ) };

	if ( $load_files[0]->{path} ) {
		# open remembered files with all properties
		Kepher::Document::Internal::restore(\%{$load_files[$_]}) for 0 .. $#load_files;
	} else {
		# or make an emty edit panel if no doc remembered
		Kepher::Document::Internal::reset();
	}




	# detect with which file to start
	$start_file_nr = 0 if ( !$start_file_nr or $start_file_nr < 0 );
	$start_file_nr = $intern->{'loaded'}-1 if 
		$start_file_nr >= $intern->{'loaded'} and $intern->{'loaded'};

	Kepher::Edit::Bookmark::restore_all();
	Kepher::App::EditPanel::Margin::reset_line_number_width();
	Kepher::Document::Internal::eval_properties($#load_files);
	Kepher::Document::Change::to_number($start_file_nr);
	Kepher::Document::_set_previous_nr($start_file_nr);
}

sub delete {
	delete $Kepher::document{'open'}
		if $Kepher::config{'file'}{'current'}{'session'}{'save'} eq 'not' 
		or $Kepher::config{'file'}{'current'}{'session'}{'save'} eq 'extern';
}

# intern
sub _forget_gone_files {
	my @true_files = ();
	my $node       = shift;
	$node = $$node if ref $node eq 'REF' and ref $$node eq 'ARRAY';
	if ( ref $node eq 'ARRAY' ) {
		my @files = @{$node};
		for ( 0 .. $#files ) {
			if ( defined $files[$_]{'path'} and -e $files[$_]{'path'} ) {
				my %file_properties = %{ $files[$_] };
				push( @true_files, \%file_properties );
			}
		}
	}
	return \@true_files;
}

sub _remember_directory {
	my ( $filename, $dir, @dirs ) = shift;
	if ( length($filename) > 0 ) {
		@dirs = split( /\\/, $filename ) if ( $filename =~ /\\/ );
		@dirs = split( /\//, $filename ) if ( $filename =~ /\// );
		$dir .= "$dirs[$_]/" for 0 .. $#dirs - 1;
		$Kepher::config{'file'}{'current'}{'session'}{'directory'} = $dir if $dir;
	}

}

1;