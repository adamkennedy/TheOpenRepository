package KEPHER::File::Session;
$VERSION = '0.11';

use strict;

# extern
sub load {
	my $file_name = KEPHER::Dialog::get_file_open(
		KEPHER::App::Window::_get(),
		$KEPHER::localisation{'dialog'}{'file'}{'open_session'},
		$KEPHER::config{'file'}{'current'}{'session'}{'directory'},
		$KEPHER::internal{'file'}{'filterstring'}{'config'}
	);
	if ( -r $file_name ) {
		my %temp_config = %{ KEPHER::Config::File::load($file_name) };
		if (%temp_config) {
			KEPHER::File::close_all();
			my $start_node = $KEPHER::config{'file'}{'current'}{'session'}{'node'};
			my @load_files = @{ KEPHER::Config::_convert_node_2_AoH(
					\$temp_config{$start_node}{'open'}
			) };
			my $start_file_nr = $temp_config{$start_node}{'current_nr'};
			@load_files = @{ &_forget_gone_files( \@load_files ) };

			# open remembered files with all properties
			KEPHER::Document::Internal::restore( \%{ $load_files[$_] } )
				for ( 0 .. $#load_files );

			# how many buffer we currently have and save the last doc?
			my $buffer = $KEPHER::internal{'document'}{'buffer'};
			KEPHER::Document::Internal::eval_properties($buffer-1);

			# slecting starting doc
			$start_file_nr = 0
				if (not defined $start_file_nr) or ($start_file_nr < 0 );
			$start_file_nr = $buffer - 1 if $start_file_nr >= $buffer ;

			# activate the starting document & some afterwork
			KEPHER::Document::Change::to_number($start_file_nr);
			KEPHER::Document::_set_previous_nr($start_file_nr);
			_remember_directory($file_name);
		} else {
			KEPHER::Dialog::warning_box(undef, $file_name,
			    $KEPHER::localisation{'dialog'}{'error'}{'config_parse'});
		}
	}
}

sub add {
	my $file_name = KEPHER::Dialog::get_file_open(
		KEPHER::App::Window::_get(),
		$KEPHER::localisation{'dialog'}{'file'}{'add_session'},
		$KEPHER::config{'file'}{'current'}{'session'}{'directory'},
		$KEPHER::internal{'file'}{'filterstring'}{'config'}
	);
	if ( -r $file_name ) {
		my %temp_config = %{ KEPHER::Config::File::load($file_name) };
		if (%temp_config) {
			my $current_doc_nr = $KEPHER::document{'current_nr'};
			my $prev_doc_nr    = $KEPHER::document{'previous_nr'};
			my $start_node
				= $KEPHER::config{'file'}{'current'}{'session'}{'node'};
			my @load_files = @{ KEPHER::Config::_convert_node_2_AoH(
					\$temp_config{$start_node}{'open'}
			) };
			@load_files = @{ _forget_gone_files( \@load_files ) };

			# open remembered files with all properties
			KEPHER::Document::Internal::save_properties($current_doc_nr);
			KEPHER::Document::Internal::restore( \%{ $load_files[$_] } )
				for ( 0 .. $#load_files );

			# make file history like before
			KEPHER::Document::Internal::change_pointer($current_doc_nr);
			KEPHER::Document::Internal::eval_properties($current_doc_nr);
			_remember_directory($file_name);
		} else {
			KEPHER::Dialog::warning_box(undef, $file_name,
			    $KEPHER::localisation{'dialog'}{'error'}{'config_parse'});
		}
	}
}

sub save {
	my $config_file = shift;
	$config_file = $KEPHER::internal{path}{config}
		. $KEPHER::config{'file'}{'current'}{'session'}{'file'}
		unless $config_file;
	my $start_node = shift;
	$start_node = $KEPHER::config{'file'}{'current'}{'session'}{'node'}
		unless $start_node;
	my %temp_config;
	%temp_config = %{ &KEPHER::Config::File::load($config_file) }
		if ( -r $config_file );
	undef $temp_config{$start_node}{'open'};
	&KEPHER::Config::_convert_node_2_AoH( \$KEPHER::document{'open'} );
	@{ $KEPHER::document{'open'} }
		= @{ _forget_gone_files( \$KEPHER::document{'open'} ) };
	@{ $temp_config{$start_node}{'open'} } = @{ $KEPHER::document{'open'} };
	$temp_config{$start_node}{'current_nr'} = $KEPHER::document{'current_nr'};
	KEPHER::Config::File::store( $config_file, \%temp_config );
}

sub save_as {
	my $file_name = KEPHER::Dialog::get_file_save( KEPHER::App::Window::_get(),
		$KEPHER::localisation{'dialog'}{'file'}{'save_session'},
		$KEPHER::config{'file'}{'current'}{'session'}{'directory'},
		$KEPHER::internal{'file'}{'filterstring'}{'config'}
	);
	if ( length($file_name) > 0 ) {
		&save( $file_name, "files" );
		_remember_directory($file_name);
	}
}

sub import_scite {
	my $win = KEPHER::App::Window::_get();
	my $file_name = KEPHER::Dialog::get_file_open( $win,
		$KEPHER::localisation{'dialog'}{'file'}{'open_session'},
		$KEPHER::internal{'path'}{'config'},
		$KEPHER::internal{'file'}{'filterstring'}{'scite'}
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
				&KEPHER::File::close_all;
				for (@load_files) {
					KEPHER::Document::Internal::add( ${$_}{'path'} );
					KEPHER::Edit::_goto_pos( ${$_}{'cursorpos'} );
				}
				KEPHER::Document::Change::to_number($start_file_nr);
				$KEPHER::document{'previous_nr'} = $start_file_nr;
			} else {
				KEPHER::Dialog::warning_box( $win, $file_name,
					$KEPHER::localisation{'dialog'}{'error'}{'config_parse'} );
			}
		} else {
			my $err_msg = $KEPHER::localisation{'dialog'}{'error'};
			KEPHER::Dialog::warning_box 
				($win, $err_msg->{file_read}." $file_name", $err_msg->{file});
		}
	}
}

sub export_scite {
	my $win = KEPHER::App::Window::_get();
	my $file_name = KEPHER::Dialog::get_file_save( $win,
		$KEPHER::localisation{'dialog'}{'file'}{'save_session'},
		$KEPHER::internal{'path'}{'config'},
		$KEPHER::internal{'file'}{'filterstring'}{'scite'}
	);
	if ( length($file_name) > 0 ) {
		if ( open my $FILE, ">$file_name" ) {
			my ( $current, $output ) = ( $KEPHER::document{'current_nr'}, );
			for ( 0 .. KEPHER::Document::_get_last_nr() ) {
				my %file = %{ $KEPHER::document{'open'}[$_] };
				if ( -e $file{'path'} ) {
					$output .= "<pos=";
					$output .= "-" if $_ == $current;
					$output .= "$file{cursorpos}> $file{path}\n";
				}
			}
			print $FILE $output;
		} else {
			my $err_msg = $KEPHER::localisation{'dialog'}{'error'};
			KEPHER::Dialog::warning_box
				($win, $err_msg->{file_write}." $file_name", $err_msg->{file} );
		}
	}
}

# default session handling
sub store {
	my $config = $KEPHER::config{'file'}{'current'}{'session'};
	save( $KEPHER::internal{path}{config} . $config->{'file'} )
		if $config->{'save'} eq 'extern';
}

sub restore {
	my $config = $KEPHER::config{'file'}{'current'}{'session'};
	my $intern = $KEPHER::internal{'document'};
	my @load_files;
	my $start_file_nr = $KEPHER::document{'current_nr'};
	$start_file_nr ||= 0;
	$KEPHER::document{'current_nr'} = 0;
	$KEPHER::internal{'document'}{'changed'}= 0;
	$KEPHER::internal{'document'}{'loaded'} = 0;

	# detect wich files to load
	if ( $config->{'save'} eq 'not' ) { }
	elsif ( $config->{'save'} eq 'intern' ) {
		@load_files = @{ KEPHER::Config::_convert_node_2_AoH( \$KEPHER::document{open} ) };
	} elsif ( $config->{'save'} eq 'extern' ) {
		my $file_name = $KEPHER::internal{path}{config} . $config->{'file'};
		my $start_node  = $config->{'node'};
		my %temp_config = %{ KEPHER::Config::File::load($file_name) };
		@load_files = @{
			KEPHER::Config::_convert_node_2_AoH( \$temp_config{$start_node}{'open'} )
		};
		$start_file_nr = $temp_config{$start_node}{'current_nr'};
	}

	# afterwork
	undef $KEPHER::document{'open'};
	@load_files = @{ &_forget_gone_files( \@load_files ) };

	# open remembered files with all properties
	if ( $load_files[0]{'path'} ) {
		KEPHER::Document::Internal::restore(\%{$load_files[$_]}) for 0..$#load_files;
	}
	# or make an emty edit panel if no doc remembered
	else { KEPHER::Document::Internal::reset() }




	# detect with which file to start
	$start_file_nr = 0 if ( !$start_file_nr or $start_file_nr < 0 );
	$start_file_nr = $intern->{'loaded'}-1 if 
		$start_file_nr >= $intern->{'loaded'} and $intern->{'loaded'};

	KEPHER::Edit::Bookmark::restore_all();
	KEPHER::App::EditPanel::Margin::reset_line_number_width();
	KEPHER::Document::Internal::eval_properties($#load_files);
	KEPHER::Document::Change::to_number($start_file_nr);
	KEPHER::Document::_set_previous_nr($start_file_nr);
}

sub delete {
	delete $KEPHER::document{'open'}
		if $KEPHER::config{'file'}{'current'}{'session'}{'save'} eq 'not' 
		or $KEPHER::config{'file'}{'current'}{'session'}{'save'} eq 'extern';
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
		$KEPHER::config{'file'}{'current'}{'session'}{'directory'} = $dir if $dir;
	}

}

1;