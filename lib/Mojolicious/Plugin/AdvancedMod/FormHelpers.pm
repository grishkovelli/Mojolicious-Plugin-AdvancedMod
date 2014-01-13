package Mojolicious::Plugin::AdvancedMod::FormHelpers;

sub init {
}

sub _botton_to {
  my ( $self, $content ) = ( shift, shift );
  my %opt = @_;
  my $ret = '<form ';

  foreach my $k ( keys %opt ) {
    next if $k eq 'data' || $k eq 'html';
    $ret .= qq~$k="$opt{$k}"~;
  }

  $ret .= '>';

  foreach my $k ( keys %{ $opt{data} } ) {
    $opt{data}{$k} ||= '';
    $ret .= qq~<input name="$k" type="hidden" value="$opt{data}{$k}">~;
  }

  $ret .= qq~<input value="$content" type="submit" class="btn btn-link btn-sm" />~;
  $ret .= '</form>';

  return $ret;
}

1;
