package Nlib;
# this is a weechat perl library
use strict; use warnings;

# to read the following docs, you can use "perldoc Nlib.pm"

=head1 NAME

Nlib - weechat perl library with helper functions for infolists and to
map screen coordinates

=head1 USAGE

To use this library in a weechat perl script, put the library file in
either the weechat perl directory or in the same place as the script
file you use in the C</perl load> command.

Then, add the following preamble to your script, replacing
C<YOUR_SCRIPT_NAME_HERE> with the name of your script and the call to
C<weechat::register> with the appropriate data:

  use constant SCRIPT_NAME => 'YOUR_SCRIPT_NAME_HERE';
  weechat::register(SCRIPT_NAME, 'Author <address>', '9.99', 'License', 'Script description', 'stop_script_function', 'parameters');
  sub SCRIPT_FILE() {
  	my $infolistptr = weechat::infolist_get('perl_script', '', SCRIPT_NAME);
  	my $filename = weechat::infolist_string($infolistptr, 'filename') if weechat::infolist_next($infolistptr);
  	weechat::infolist_free($infolistptr);
  	return $filename unless @_;
  	my $sep = weechat::info_get('dir_separator', '');
  	my @path = split $sep, $filename;
  	my $link = readlink $filename;
  	my @lpath = split $sep, $link if defined $link;
  	(join '/', @path[0..$#path-1]),
  	($path[-2] eq 'autoload' ? join '/', @path[0..$#path-2] : ()),
  	(@lpath ? join '/', ($lpath[0] ne '' ? @path[0..$#path-1] : ''), @lpath[0..$#lpath-1] : ()),
  	(join '/', (split $sep, weechat::info_get('weechat_dir', '')), 'perl')
  }
  require lib; lib->import(&SCRIPT_FILE(1));
  require Nlib;

To use the functions provided herein, call them with C<Nlib::function_name parameters...>

=head1 FUNCTION DESCRIPTION

for full pod documentation, filter this script with

  perl -pE'
  (s/^## (.*?) -- (.*)/=head2 $1\n\n$2\n\n=over\n/ and $o=1) or
   s/^## (.*?) - (.*)/=item I<$1>\n\n$2\n/ or
  (s/^## (.*)/=back\n\n$1\n\n=cut\n/ and $o=0,1) or
  ($o and $o=0,1 and s/^sub /=back\n\n=cut\n\nsub /)'

=cut

## i2h -- copy weechat infolist content into perl hash
## $infolist - name of the infolist in weechat
## $ptr - pointer argument (infolist dependend)
## @args - arguments to the infolist (list dependend)
## $fields - string of ref type "fields" if only certain keys are needed (optional)
## returns perl list with perl hashes for each infolist entry
sub i2h {
	my %i2htm = (i => 'integer', s => 'string', p => 'pointer', b => 'buffer', t => 'time');
	local *weechat::infolist_buffer = sub { '(not implemented)' };
	my ($infolist, $ptr, @args) = @_;
	$ptr ||= "";
	my $fields = ref $args[-1] eq 'fields' ? ${ pop @args } : undef;
	my $infptr = weechat::infolist_get($infolist, $ptr, do { local $" = ','; "@args" });
	my @infolist;
	while (weechat::infolist_next($infptr)) {
		my @fields = map {
			my ($t, $v) = split ':', $_, 2;
			bless \$v, $i2htm{$t};
		}
		split ',',
			($fields || weechat::infolist_fields($infptr));
		push @infolist, +{ do {
			my (%list, %local, @local);
			map {
				my $fn = 'weechat::infolist_'.ref $_;
				my $r = do { no strict 'refs'; &$fn($infptr, $$_) };
				if ($$_ =~ /^localvar_name_(\d+)$/) {
					$local[$1] = $r;
					()
				}
				elsif ($$_ =~ /^(localvar)_value_(\d+)$/) {
					$local{$local[$2]} = $r;
					$1 => \%local
				}
				elsif ($$_ =~ /(.*?)((?:_\d+)+)$/) {
					my ($key, $idx) = ($1, $2);
					my @idx = split '_', $idx; shift @idx;
					my $target = \$list{$key};
					for my $x (@idx) {
						my $o = 1;
						if ($key eq 'key' or $key eq 'key_command') {
							$o = 0;
						}
						if ($x-$o < 0) {
							local $" = '|';
							weechat::print('',"list error: $target/$$_/$key/$x/$idx/@idx(@_)");
							$o = 0;
						}
						$target = \$$target->[$x-$o]
					}
					$$target = $r;

					$key => $list{$key}
				}
				else {
					$$_ => $r
				}
			} @fields
		} };
	}
	weechat::infolist_free($infptr);
	!wantarray && @infolist ? \@infolist : @infolist
}

## hdh -- hdata helper
## $_[0] - arg pointer or hdata list name
## $_[1] - hdata name
## $_[2..$#_] - hdata variable name
## $_[-1] - hashref with key/value to update (optional)
## returns value of hdata, and hdata name in list ctx, or number of variables updated
sub hdh {
	if (@_ > 1 && $_[0] !~ /^0x/ && $_[0] !~ /^\d+$/) {
		my $arg = shift;
		unshift @_, weechat::hdata_get_list(weechat::hdata_get($_[0]), $arg);
	}
	while (@_ > 2) {
		my ($arg, $name, $var) = splice @_, 0, 3;
		my $hdata = weechat::hdata_get($name);

		unless (ref $var eq 'HASH') {
			$var =~ s/!(.*)/weechat::hdata_get_string($hdata, $1)/e;
			(my $plain_var = $var) =~ s/^\d+\|//;
			my $type = weechat::hdata_get_var_type_string($hdata, $plain_var);
			if ($type eq 'pointer') {
				my $name = weechat::hdata_get_var_hdata($hdata, $var);
				unshift @_, $name if $name;
			}
			if ($type eq 'shared_string') {
			    $type =~ s/shared_//;
			}

			my $fn = "weechat::hdata_$type";
			unshift @_, do { no strict 'refs';
							 &$fn($hdata, $arg, $var) };
		}
		else {
			return weechat::hdata_update($hdata, $arg, $var);
		}
	}
	wantarray ? @_ : $_[0]
}

## l2l -- copy weechat list into perl list
## $ptr - weechat list pointer
## $clear - if true, clear weechat list
## returns perl list
sub l2l {
	my ($ptr, $clear) = @_;
	my $itemptr = weechat::list_get($ptr, 0);
	my @list;
	while ($itemptr) {
		push @list, weechat::list_string($itemptr);
		$itemptr = weechat::list_next($itemptr);
	}
	weechat::list_remove_all($ptr) if $clear;
	@list
}

## find_bar_window -- find the bar window where the coordinates belong to
## $row - row
## $col - column
## returns bar window infolist and bar infolist in a array ref if found
sub find_bar_window {
	my ($row, $col) = @_;

	my $barwinptr;
	my $bar_info;
	for (i2h('bar_window')) {
		return [ $_, $bar_info ] if
			$row > $_->{'y'} && $row <= $_->{'y'}+$_->{'height'} &&
				$col > $_->{'x'} && $col <= $_->{'x'}+$_->{'width'} &&
					(($bar_info)=i2h('bar', $_->{'bar'})) && !$bar_info->{'hidden'};
	}
	
}

## in_window -- check if given coordinates are in a window
## $row - row
## $col - column
## $wininfo - infolist of window to check
## returns true if in window
sub in_window {
	my ($row, $col, $wininfo) = @_;

	# in window?
	$row > $wininfo->{'y'} &&
		$row <= $wininfo->{'y'}+$wininfo->{'height'} &&
			$col > $wininfo->{'x'} &&
				$col <= $wininfo->{'x'}+$wininfo->{'width'}
}

## in_chat_window -- check if given coordinates are in the chat part of a window
## $row - row
## $col - column
## $wininfo - infolist of window to check
## returns true if in chat part of window
sub in_chat_window {
	my ($row, $col, $wininfo) = @_;

	# in chat window?
	$row > $wininfo->{'chat_y'} &&
		$row <= $wininfo->{'chat_y'}+$wininfo->{'chat_height'} &&
			$col > $wininfo->{'chat_x'} &&
				$col <= $wininfo->{'chat_x'}+$wininfo->{'chat_width'}
}

## has_true_value -- some constants for "true"
## $v - value string
## returns true if string looks like a true thing
sub has_true_value {
	my $v = shift || '';
	$v =~ /^(?:on|yes|y|true|t|1)$/i
}

## has_false_value -- some constants for "false"
## $v - value string
## returns true if string looks like a B<false> thing
sub has_false_value {
	my $v = shift || '';
	$v =~ /^(?:off|no|n|false|f|0)?$/i
}

## hook_dynamic -- weechat::hook something and store hook reference
## $hook_call - hook type (e.g. modifier)
## $what - event type to hook (depends on $hook_call)
## $sub - subroutine name to install
## @params - parameters
sub hook_dynamic {
	my ($hook_call, $what, $sub, @params) = @_;
	my $caller_package = (caller)[0];
	eval qq{
		package $caller_package;
		no strict 'vars';
		\$DYNAMIC_HOOKS{\$what}{\$sub} =
			weechat::hook_$hook_call(\$what, \$sub, \@params)
				unless exists \$DYNAMIC_HOOKS{\$what} &&
					exists \$DYNAMIC_HOOKS{\$what}{\$sub};
	};
	die $@ if $@;
}

## unhook_dynamic -- weechat::unhook something where hook reference has been stored with hook_dynamic
## $what - event type that was hooked
## $sub - subroutine name that was installed
sub unhook_dynamic {
	my ($what, $sub) = @_;
	my $caller_package = (caller)[0];
	eval qq{
		package $caller_package;
		no strict 'vars';
		weechat::unhook(\$DYNAMIC_HOOKS{\$what}{\$sub})
			if exists \$DYNAMIC_HOOKS{\$what} &&
				exists \$DYNAMIC_HOOKS{\$what}{\$sub};
		delete \$DYNAMIC_HOOKS{\$what}{\$sub};
		delete \$DYNAMIC_HOOKS{\$what} unless \%{\$DYNAMIC_HOOKS{\$what}};
	};	
	die $@ if $@;
}

## bar_filling -- get current filling according to position
## $bar_infos - info about bar (from find_bar_window)
## returns filling as an integer number
sub bar_filling {
	my ($bar_infos) = @_;
	($bar_infos->[-1]{'position'} <= 1 ? $bar_infos->[-1]{'filling_top_bottom'}
	 : $bar_infos->[-1]{'filling_left_right'})
}

sub fu8on(@) {
	Encode::_utf8_on($_) for @_; wantarray ? @_ : shift
}

sub screen_length($) {
	weechat::strlen_screen($_[0])
}

## bar_column_max_length -- get max item length for column based filling
## $bar_infos - info about bar (from find_bar_window)
## returns max item length
sub bar_column_max_length {
	my ($bar_infos) = @_;
	my @items;
	for (@{ $bar_infos->[0]{'items_content'} }) {
		push @items, split "\n", join "\n", @$_;
	}
	my $max_length = 0;
	for (@items) {
		my $item_length = screen_length fu8on weechat::string_remove_color($_, '');
		$max_length = $item_length if $max_length < $item_length;
	}
	$max_length;
}

## find_bar_item_pos -- get position of an item in a bar structure
## $bar_infos - instance and general info about bar (from find_bar_window)
## $search - search pattern for item name
## returns (outer position, inner position, true if found)
sub find_bar_item_pos {
	my ($bar_infos, $search) = @_;
	my $item_pos_a = 0;
	my $item_pos_b;
	for (@{ $bar_infos->[-1]{'items_array'} }) {
		$item_pos_b = 0;
		for (@$_) {
			return ($item_pos_a, $item_pos_b, 1)
				if $_ =~ $search;
			++$item_pos_b;
		}
		++$item_pos_a;
	}
	(undef, undef, undef)
}

## bar_line_wrap_horiz -- apply linebreak for horizontal bar filling
## $prefix_col_r - reference to column counter
## $prefix_y_r - reference to row counter
## $bar_infos - info about bar (from find_bar_window)
sub bar_line_wrap_horiz {
	my ($prefix_col_r, $prefix_y_r, $bar_infos) = @_;
	while ($$prefix_col_r > $bar_infos->[0]{'width'}) {
		++$$prefix_y_r;
		$$prefix_col_r -= $bar_infos->[0]{'width'};
	}
}

## bar_lines_column_vert -- count lines in column layout
## $bar_infos - info about bar (from find_bar_window)
## returns lines needed for columns_horizontal layout
sub bar_lines_column_vert {
	my ($bar_infos) = @_;
	my @items;
	for (@{ $bar_infos->[0]{'items_content'} }) {
		push @items, split "\n", join "\n", @$_;
	}
	my $max_length = bar_column_max_length($bar_infos);
	my $dummy_col = 1;
	my $lines = 1;
	for (@items) {
		if ($dummy_col+$max_length > 1+$bar_infos->[0]{'width'}) {
			++$lines;
			$dummy_col = 1;
		}
		$dummy_col += 1+$max_length;
	}
	$lines;
}

## bar_items_skip_to -- skip several bar items on search for subitem position
## $bar_infos - info about bar (from find_bar_window)
## $search - patter of item to skip to
## $col - pointer column
## $row - pointer row
sub bar_items_skip_to {
	my ($bar_infos, $search, $col, $row) = @_;
	$col += $bar_infos->[0]{'scroll_x'};
	$row += $bar_infos->[0]{'scroll_y'};
	my ($item_pos_a, $item_pos_b, $found) = 
		find_bar_item_pos($bar_infos, $search);

	return 'item position not found' unless $found;

	# extract items to skip
	my $item_join = 
		(bar_filling($bar_infos) <= 1 ? '' : "\n");
	my @prefix;
	for (my $i = 0; $i < $item_pos_a; ++$i) {
		push @prefix, split "\n", join $item_join, @{ $bar_infos->[0]{'items_content'}[$i] };
	}
	push @prefix, split "\n", join $item_join, @{ $bar_infos->[0]{'items_content'}[$item_pos_a] }[0..$item_pos_b-1] if $item_pos_b;

	# cursor
	my $prefix_col = 1;
	my $prefix_y = 1;
	my $item_max_length;
	my $col_vert_lines;

	# forward cursor
	if (!bar_filling($bar_infos)) {
		my $prefix = join ' ', @prefix;
		$prefix_col += screen_length fu8on weechat::string_remove_color($prefix, '');
		++$prefix_col if @prefix && !$item_pos_b;
		bar_line_wrap_horiz(\($prefix_col, $prefix_y), $bar_infos);
	}
	elsif (bar_filling($bar_infos) == 1) {
		$prefix_y += @prefix;
		if ($item_pos_b) {
			--$prefix_y;
			$prefix_col += screen_length fu8on weechat::string_remove_color($prefix[-1], '');
		}
	}
	elsif (bar_filling($bar_infos) == 2) {
		$item_max_length = bar_column_max_length($bar_infos);
		for (@prefix) {
			$prefix_col += 1+$item_max_length;
			if ($prefix_col+$item_max_length > 1+$bar_infos->[0]{'width'}) {
				++$prefix_y;
				$prefix_col = 1;
			}
		}
	}
	elsif (bar_filling($bar_infos) == 3) {
		$item_max_length = bar_column_max_length($bar_infos);
		$col_vert_lines = $bar_infos->[-1]{'position'} <= 1 ? bar_lines_column_vert($bar_infos) : $bar_infos->[0]{'height'};
		my $pfx_idx = 0;
		for (@prefix) {
			$prefix_y = 1+($pfx_idx % $col_vert_lines);
			$prefix_col = 1+(1+$item_max_length)*(int($pfx_idx / $col_vert_lines)+1);
			return 'in prefix'
				if ($prefix_y == $row && $prefix_col > $col);
			++$pfx_idx;
		}
		$prefix_y = 1+(@prefix % $col_vert_lines);
		$prefix_col = 1+(1+$item_max_length)*int(@prefix / $col_vert_lines);
	}

	(undef,
	 $item_pos_a, $item_pos_b,
	 $prefix_col, $prefix_y,
	 (scalar @prefix),
	 $item_max_length, $col_vert_lines)
}

## bar_item_get_subitem_at -- extract subitem from a bar item at given coords
## $bar_infos - info about bar
## $search - search pattern for item whose subitems to get
## $col - pointer column
## $row - pointer row
## returns error message, subitem index, subitem text
sub bar_item_get_subitem_at {
	my ($bar_infos, $search, $col, $row) = @_;

	my ($error,
		$item_pos_a, $item_pos_b,
		$prefix_col, $prefix_y,
		$prefix_cnt,
		$item_max_length, $col_vert_lines) = 
			bar_items_skip_to($bar_infos, $search, $col, $row);

	$col += $bar_infos->[0]{'scroll_x'};
	$row += $bar_infos->[0]{'scroll_y'};

	return $error if $error;
	
	return 'no viable position'
		unless (($row == $prefix_y  && $col >= $prefix_col) || $row > $prefix_y || bar_filling($bar_infos) >= 3);

	my @subitems = split "\n", $bar_infos->[0]{'items_content'}[$item_pos_a][$item_pos_b];
	my $idx = 0;
	for (@subitems) {
		my ($beg_col, $beg_y) = ($prefix_col, $prefix_y);
		$prefix_col += screen_length fu8on weechat::string_remove_color($_, '');
		if (!bar_filling($bar_infos)) {
			bar_line_wrap_horiz(\($prefix_col, $prefix_y), $bar_infos);
		}

		return (undef, $idx, $_, [$beg_col, $col, $prefix_col, $beg_y, $row, $prefix_y])
			if (($prefix_col > $col && $row == $prefix_y) || ($row < $prefix_y && bar_filling($bar_infos) < 3));

		++$idx;

		if (!bar_filling($bar_infos)) {
			++$prefix_col;
			return ('outside', $idx-1, $_)
				if ($prefix_y == $row && $prefix_col > $col);
		}
		elsif (bar_filling($bar_infos) == 1) {
			return ('outside', $idx-1, $_)
				if ($prefix_y == $row && $col >= $prefix_col);
			++$prefix_y;
			$prefix_col = 1;
		}
		elsif (bar_filling($bar_infos) == 2) {
			$prefix_col += 1+$item_max_length-(($prefix_col-1)%($item_max_length+1));

			return ('outside', $idx-1, $_)
				if ($prefix_y == $row && $prefix_col > $col);

			if ($prefix_col+$item_max_length > 1+$bar_infos->[0]{'width'}) {
				return ('outside item', $idx-1, $_)
					if ($prefix_y == $row && $col >= $prefix_col);
				
				++$prefix_y;
				$prefix_col = 1;
			}
		}
		elsif (bar_filling($bar_infos) == 3) {
			$prefix_col += 1+$item_max_length-(($prefix_col-1)%($item_max_length+1));
			return ('outside', $idx-1, $_)
				if ($prefix_y == $row && $prefix_col > $col);
			$prefix_y = 1+(($idx+$prefix_cnt) % $col_vert_lines);
			$prefix_col = 1+(1+$item_max_length)*int(($idx+$prefix_cnt) / $col_vert_lines);

		}
	}
	'not found';
}

## bar_item_get_item_and_subitem_at -- gets item and subitem at position
## $bar_infos - info about bar
## $col - pointer column
## $row - pointer row
## returns generic item, error if outside subitem, index of subitem and text of subitem
sub bar_item_get_item_and_subitem_at {
	my ($bar_infos, $col, $row) = @_;
	my $item_pos_a = 0;
	my $item_pos_b;
	for (@{ $bar_infos->[-1]{'items_array'} }) {
		$item_pos_b = 0;
		for (@$_) {
			my $g_item = "^\Q$_\E\$";
			my ($error, @rest) =
				bar_item_get_subitem_at($bar_infos, $g_item, $col, $row);
			return ($_, $error, @rest)
				if (!defined $error || $error =~ /^outside/);
			return () if $error eq 'no viable position';
			++$item_pos_b;
		}
		++$item_pos_a;
	}
	()
}

use Pod::Select qw();
use Pod::Simple::TextContent;

## get_desc_from_pod -- return setting description from pod documentation
## $file - filename with pod
## $setting - name of setting
## returns description as text
sub get_desc_from_pod {
	my $file = shift;
	return unless -s $file;
	my $setting = shift;

	open my $pod_sel, '>', \my $ss;
	Pod::Select::podselect({
	   -output => $pod_sel,
	   -sections => ["SETTINGS/$setting"]}, $file);

	my $pt = new Pod::Simple::TextContent;
	$pt->output_string(\my $ss_f);
	$pt->parse_string_document($ss);

	my ($res) = $ss_f =~ /^\s*\Q$setting\E\s+(.*)\s*/;
	$res
}

## get_settings_from_pod -- retrieve all settings in settings section of pod
## $file - file with pod
## returns list of all settings
sub get_settings_from_pod {
	my $file = shift;
	return unless -s $file;

	open my $pod_sel, '>', \my $ss;
	Pod::Select::podselect({
	   -output => $pod_sel,
	   -sections => ["SETTINGS//!.+"]}, $file);

	$ss =~ /^=head2\s+(.*)\s*$/mg
}

## mangle_man_for_wee -- turn man output into weechat codes
## @_ - list of grotty lines that should be turned into weechat attributes
## returns modified lines and modifies lines in-place
sub mangle_man_for_wee {
	for (@_) {
		s/_\x08(.)/weechat::color('underline').$1.weechat::color('-underline')/ge;
		s/(.)\x08\1/weechat::color('bold').$1.weechat::color('-bold')/ge;
	}
	wantarray ? @_ : $_[0]
}

## read_manpage -- read a man page in weechat window
## $file - file with pod
## $name - buffer name
sub read_manpage {
	my $caller_package = (caller)[0];
	my $file = shift;
	my $name = shift;

	if (my $obuf = weechat::buffer_search('perl', "man $name")) {
		eval qq{
			package $caller_package;
			weechat::buffer_close(\$obuf);
		};
	}

	my @wee_keys = Nlib::i2h('key');
	my @keys;

	my $winptr = weechat::current_window();
	my ($wininfo) = Nlib::i2h('window', $winptr);
	my $buf = weechat::buffer_new("man $name", '', '', '', '');
	return weechat::WEECHAT_RC_OK unless $buf;

	my $width = $wininfo->{'chat_width'};
	--$width if $wininfo->{'chat_width'} < $wininfo->{'width'} || ($wininfo->{'width_pct'} < 100 && (grep { $_->{'y'} == $wininfo->{'y'} } Nlib::i2h('window'))[-1]{'x'} > $wininfo->{'x'});
	$width -= 2; # when prefix is shown

	weechat::buffer_set($buf, 'time_for_each_line', 0);
	eval qq{
		package $caller_package;
		weechat::buffer_set(\$buf, 'display', 'auto');
	};
	die $@ if $@;

	@keys = map { $_->{'key'} }
		grep { $_->{'command'} eq '/input history_previous' ||
			   $_->{'command'} eq '/input history_global_previous' } @wee_keys;
	@keys = 'meta2-A' unless @keys;
	weechat::buffer_set($buf, "key_bind_$_", '/window scroll -1') for @keys;

	@keys = map { $_->{'key'} }
		grep { $_->{'command'} eq '/input history_next' ||
			   $_->{'command'} eq '/input history_global_next' } @wee_keys;
	@keys = 'meta2-B' unless @keys;
	weechat::buffer_set($buf, "key_bind_$_", '/window scroll +1') for @keys;

	weechat::buffer_set($buf, 'key_bind_ ', '/window page_down');

	@keys = map { $_->{'key'} }
		grep { $_->{'command'} eq '/input delete_previous_char' } @wee_keys;
	@keys = ('ctrl-?', 'ctrl-H') unless @keys;
	weechat::buffer_set($buf, "key_bind_$_", '/window page_up') for @keys;

	weechat::buffer_set($buf, 'key_bind_g', '/window scroll_top');
	weechat::buffer_set($buf, 'key_bind_G', '/window scroll_bottom');

	weechat::buffer_set($buf, 'key_bind_q', '/buffer close');

	weechat::print($buf, " \t".mangle_man_for_wee($_)) # weird bug with \t\t showing nothing?
			for `pod2man \Q$file\E 2>/dev/null | GROFF_NO_SGR=1 nroff -mandoc -rLL=${width}n -rLT=${width}n -Tutf8 2>/dev/null`;
	weechat::command($buf, '/window scroll_top');

	unless (hdh($buf, 'buffer', 'lines', 'lines_count') > 0) {
		weechat::print($buf, weechat::prefix('error').$_)
				for "Unfortunately, your @{[weechat::color('underline')]}nroff".
					"@{[weechat::color('-underline')]} command did not produce".
					" any output.",
					"Working pod2man and nroff commands are required for the ".
					"help viewer to work.",
					"In the meantime, please use the command ", '',
					"\tperldoc $file", '',
					"on your shell instead in order to read the manual.",
					"Thank you and sorry for the inconvenience."
	}
}

1
