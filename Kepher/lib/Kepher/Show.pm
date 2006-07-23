package PCE::Show;
$VERSION = '0.11';

use strict;
use Cwd;

# open file will full absolut path
sub _of{
	my $file_path = shift;
	my $file_name = shift;
	PCE::Document::Internal::add( $file_path.$file_name );#getcwd().'/'.
}
# config file
sub _cf { _of($PCE::internal{path}{config}, shift) }
#
sub localisation_file  { _cf "localisation/$_[0].conf"}
sub syntaxmode_file    { _cf "syntaxhighlighter/$_[0].pm"}
sub interface_file     {
	my $item = shift;
	return unless exists $PCE::config{'app'}{$item};
	my $file = $PCE::config{'app'}{$item}{'file'};
	$file = $PCE::config{'app'}{$item}{'defaultfile'} if $item eq 'contextmenu';
	$file = $PCE::config{'app'}{'toolbar'}{'defaultfile'} if $item eq 'toolbar';
	_cf $file;
}

# help file
sub _hf { _of($PCE::internal{path}{help}, shift)}
#
sub history              { _hf "english/internals/history.txt"}
sub thoughts_mission     { _hf "english/thoughts/mission.txt"}
sub thoughts_manifest    { _hf "deutsch/interna/manifest.txt"}
sub thoughts_gpl         { _hf "english/thoughts/gpl.txt"}
sub thoughts_perlrules   { _hf "deutsch/interna/perlrules.txt"}
sub thoughts_modulenames { _hf "deutsch/interna/modulnamen.txt"}
sub licence_art          { _hf "english/license/artistic.txt"}
sub licence_acl          { _hf "english/license/acl.txt"}
sub licence_wxwl         { _hf "english/license/wx.txt"}
sub licence_lgpl         { _hf "english/license/lgpl.txt"}
sub licence_sci          { _hf "english/license/scintilla.txt"}
sub welcome              { _hf $PCE::config{'texts'}{'welcome'}}
sub version_text         { _hf $PCE::config{'texts'}{'version'}}
sub licence_gpl          { _hf $PCE::config{'texts'}{'license'}}
sub feature_tour         { _hf $PCE::config{'texts'}{'feature'}}
sub navigation_guide     { _hf $PCE::config{'texts'}{'navigation'}}
sub credits              { _hf $PCE::config{'texts'}{'credits'}}
sub keyboard_map         { _hf $PCE::config{'texts'}{'keymap'}}

1;
