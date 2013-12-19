package Mojolicious::Plugin::AdvancedMod;
use Mojo::Base 'Mojolicious::Plugin';

use Mojolicious::Plugin::AdvancedMod::ActionFilter;
use Mojolicious::Plugin::AdvancedMod::HashedParams;
use Mojolicious::Plugin::AdvancedMod::ModeSwitcher;

use Data::Dumper;

our $VERSION = '0.31';

sub register {
  my ( $plugin, $app, $c ) = @_;

  my %helpers = (
    action_filter => sub {
      my ( $self, %filters ) = @_;
      Mojolicious::Plugin::AdvancedMod::ActionFilter::init( $app, \%filters );
    },
    hparams => sub {
      my ( $self, @only ) = @_;
      Mojolicious::Plugin::AdvancedMod::HashedParams::init( $self, @only ? \@only : '' );
    },
    switch_config => sub {
      my ( $self, %args ) = @_;
      Mojolicious::Plugin::AdvancedMod::HashedParams::init( $app, \%args );
    }
  );

  # add helper's
  my %only = ();
  if( $c->{only} ) {
    %only = map { $_ => 1 } @{ $c->{only} };
  }

  foreach my $h ( keys %helpers ) {
    if( %only && !exists $only{$h} ) {
      delete $helpers{$h};
      next;
    }
    $app->helper( $h => $helpers{$h} );
    $app->log->debug( "** AdvancedMod load $h" );
  }
}

1;
