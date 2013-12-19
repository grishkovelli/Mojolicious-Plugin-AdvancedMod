use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Mojolicious::Plugin::AdvancedMod',
    license             => 'Perl_5',
    dist_author         => q{Grishkovelli <grishkovelli@gmail.com>},
    dist_version_from   => 'lib/Mojolicious/Plugin/AdvancedMod.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/grishkovelli/Mojolicious-Plugin-ModeSwitcher',
        }
    },
    add_to_cleanup     => [ 'Mojolicious-Plugin-AdvancedMod-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
