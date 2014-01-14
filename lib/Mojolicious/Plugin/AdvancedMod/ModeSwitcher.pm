package Mojolicious::Plugin::AdvancedMod::ModeSwitcher;

sub init {
  my ( $app, $args ) = @_;
  my $mode = $ENV{MOJO_MODE};

  my $conf = {};

  if ( $args->{file} && -r $args->{file} ) {
    $conf = _load_file( $args->{file}, $mode );
  }

  if ( !$conf->{_err} ) {
    if ( $args->{include} ) {
      foreach my $param ( keys %{$conf} ) {
        next if $conf->{$param} !~ /\.(yml|json)$/;
        $conf->{$param} = _load_file( $conf->{$param} );
      }
    }

    if ( $args->{eval} && $args->{eval}{$mode} ) {
      my $ret = eval $args->{eval}{$mode}{code};

      if ( $@ ) {
        $conf->{_err} = $@;
      }
      else {
        if ( $args->{eval}{$mode}{key} ) {
          $conf->{ $args->{eval}{$mode}{key} } = $ret;
        }
        else {
          $conf = $ret;
        }
      }
    }

    push @{ $app->renderer->paths }, $conf->{templates_path} if $conf->{templates_path};
    push @{ $app->static->paths },   $conf->{static_path}    if $conf->{static_path};
  }

  $app->defaults( switch_config => $conf );

  return undef if $conf->{_err};
  return 1;
}

sub _load_package {
  my $ext = shift;
  my %lst = (
    yml  => [qw( YAML::XS YAML YAML::Tiny )],
    json => [qw( JSON::XS JSON Mojo::JSON )]
  );

  foreach my $pkg ( @{ $lst{$ext} } ) {
    eval "use $pkg";
    if ( !$@ ) {
      my $ret = $pkg . "::";
      if ( $pkg =~ /^YAML/ ) { $ret .= 'Load'; }
      elsif ( grep( /^$pkg$/, qw/JSON::XS JSON/ ) ) { $ret .= 'decode_json'; }
      else                                          { $ret .= 'decode'; }
      return { err => 0, name => $ret };
    }
  }
  return { err => 'No module name found' };
}

sub _load_file {
  my ( $file, $mode ) = @_;
  my $ext = ( $file =~ /\.(\w+$)/ )[0];

  my $src;
  eval {
    open my $fh, $file or return;
    $src .= $_ while <$fh>;
    close $fh;
  };

  return { _err => $@ || $! } if $@ || $!;

  my $pkg = _load_package( $ext );
  return { _err => $pkg->{err} } if $pkg->{err};

  my $res = eval $pkg->{name} . '($src)';
  return { _err => $@ } if $@;

  my $ret = {};

  if ( $mode ) {
    %$ret = map { $_ => $res->{$mode}{$_} } keys %{ $res->{$mode} };
    if ( $res->{overall} ) {
      foreach my $k ( keys %{ $res->{overall} } ) {
        $ret->{$k} = $res->{'overall'}{$k};
      }
    }
  }
  else {
    %$ret = map { $_ => $res->{$_} } keys %{$res};
  }

  return $ret;
}

1;

__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AdvancedMod::ModeSwitcher - Configuration change by MOJO_MODE

=head1 ARGUMENTS

=head2 file

Reads the yml/json stream from a file instead of a string

=head2 include

If your configuration has a file.(yml|json), ModeSwitcher replace the value of the contents of the file

=head2 eval

Eval code

=head1 SPECIAL NAMES

If your configuration has B<static_path> or B<templates_path>, ModeSwitcher will make the:

  push @{ $app->renderer->paths }, $conf->{templates_path}
  push @{ $app->static->paths },   $conf->{static_path}

=head1 SYNOPSIS

  $self->plugin( 'ModeSwitcher' );
  ...
  $self->switch_config(
    file => 'etc/conf.yml'
    eval => {
      development => {
        code => '..',
        key  => 'db'
      },
      production  => { code => '..' },
      overall => {
        secret_key: 28937489273897
      }
    },
  );
  ...
  print self->stash( 'switch_config' )->{db_name};

=head1 AUTHOR

Grishkovelli L<grishkovelli@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013, Grishkovelli.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
