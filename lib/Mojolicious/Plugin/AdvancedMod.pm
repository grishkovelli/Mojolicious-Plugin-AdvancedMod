package Mojolicious::Plugin::AdvancedMod;
use Mojo::Base 'Mojolicious::Plugin';

use Mojolicious::Plugin::AdvancedMod::ActionFilter;
use Mojolicious::Plugin::AdvancedMod::HashedParams;
use Mojolicious::Plugin::AdvancedMod::Configurator;
use Mojolicious::Plugin::AdvancedMod::FormHelpers;

use DBI;

our $VERSION = '0.33';

sub register {
  my ( $plugin, $app, $conf ) = @_;
  my ( $helpers, %only ) = {};

  Mojolicious::Plugin::AdvancedMod::ActionFilter::init( $app, $helpers );
  Mojolicious::Plugin::AdvancedMod::Configurator::init( $app, $helpers );
  Mojolicious::Plugin::AdvancedMod::HashedParams::init( $app, $helpers );
  Mojolicious::Plugin::AdvancedMod::FormHelpers::multi_init( $app, $helpers );

  # add helper's
  if ( $conf->{only} ) {
    %only = map { $_ => 1 } @{ $conf->{only} };
  }

  foreach my $h ( keys %$helpers ) {
    if ( %only && !exists $only{$h} ) {
      delete $helpers->{$h};
      next;
    }
    $app->helper( $h => $helpers->{$h} );
    $app->log->debug( "** AdvancedMod load $h" );
  }

  # by am_config
  if ( $app->defaults( 'am_config' ) ) {
    my $am_cfg = $app->defaults( 'am_config' );

    # add db helper's
    foreach my $k ( keys %$am_cfg ) {
      if ( $k eq 'db' || $k =~ /^db_\w+$/ ) {
        $app->helper(
          $k => sub {
            return DBI->connect( @{ $am_cfg->{$k} }{qw/ dsn user password options /} );
          }
        );
      }
    }

    # change 'secrets' key
    $app->secrets( $am_cfg->{secrets} ) if $am_cfg->{secrets};
  }
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AdvancedMod - More buns for Mojolicious

=head1 SYNOPSIS

  # Load all AdvancedMod Plugins
  $self->plugin('AdvancedMod');

=head1 SEE ALSO

=over 2

=item

L<Mojolicious::Plugin::AdvancedMod::ActionFilter>

=item

L<Mojolicious::Plugin::AdvancedMod::HashedParams>

=item

L<Mojolicious::Plugin::AdvancedMod::Configurator>

=item

L<Mojolicious::Plugin::AdvancedMod::FormHelpers>

=item

L<Mojolicious::Command::am>

=item

https://github.com/grishkovelli/Mojolicious-Plugin-AdvancedMod

=back

=head1 AUTHOR

Grishkovelli L<grishkovelli@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013, 2014
Grishkovelli L<grishkovelli@gmail.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
