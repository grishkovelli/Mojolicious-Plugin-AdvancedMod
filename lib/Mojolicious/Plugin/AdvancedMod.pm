package Mojolicious::Plugin::AdvancedMod;
use Mojo::Base 'Mojolicious::Plugin';

use Mojolicious::Plugin::AdvancedMod::ActionFilter;
use Mojolicious::Plugin::AdvancedMod::HashedParams;
use Mojolicious::Plugin::AdvancedMod::ModeSwitcher;
use Mojolicious::Plugin::AdvancedMod::FormHelpers;

our $VERSION = '0.31';

sub register {
  my ( $plugin, $app, $conf ) = @_;
  my ( %only, %helpers );

  %helpers = (
    action_filter => sub {
      my ( $self, %filters ) = @_;
      Mojolicious::Plugin::AdvancedMod::ActionFilter::init( $app, \%filters );
    },
    hparams => sub {
      my ( $self, @permit ) = @_;
      Mojolicious::Plugin::AdvancedMod::HashedParams::init( $self, @permit ? \@permit : '' );
    },
    switch_config => sub {
      my ( $self, %args ) = @_;
      Mojolicious::Plugin::AdvancedMod::ModeSwitcher::init( $app, \%args );
    }
  );

  Mojolicious::Plugin::AdvancedMod::FormHelpers::init( $app, \%helpers );

  # add helper's
  my %only = ();
  if ( $conf->{only} ) {
    %only = map { $_ => 1 } @{ $conf->{only} };
  }

  foreach my $h ( keys %helpers ) {
    if ( %only && !exists $only{$h} ) {
      delete $helpers{$h};
      next;
    }
    $app->helper( $h => $helpers{$h} );
    $app->log->debug( "** AdvancedMod load $h" );
  }
}

1;
