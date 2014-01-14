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

  Mojolicious::Plugin::AdvancedMod::FormHelpers::multi_init( $app, \%helpers );

  # add helper's
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

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AdvancedMod - More buns for Mojolicioius

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Mojolicious::Plugin::AdvancedMod');

  # Mojolicious::Lite
  plugin 'Mojolicious::Plugin::AdvancedMod';

=head1 SEE ALSO

=over 2

=item

L<Mojolicious::Plugin::AdvancedMod::ActionFilter>

=item

L<Mojolicious::Plugin::AdvancedMod::HashedParams>

=item

L<Mojolicious::Plugin::AdvancedMod::ModeSwitcher>

=item

L<Mojolicious::Plugin::AdvancedMod::FormHelpers>

=item

L<Mojolicious::Command::am>

=back

=head1 AUTHOR

Grishkovelli L<grishkovelli@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013, 2014
Grishkovelli L<grishkovelli@gmail.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut