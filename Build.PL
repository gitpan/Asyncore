
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
    "build_requires" => {
        "Module::Build" => "0.3601",
        "Storable" => 0,
        "Test::Fatal" => 0,
        "Test::More" => "0.88",
        "utf8" => 0
    },
    #"c_source" => "c",
    #"configure_requires" => {
    #  "Module::Build" => "0.3601"
    #},
    "dist_abstract" => "Basic infrastructure for writing asynchronous socket service",
    "dist_author" => [
    "Sebastiano Piccoli <sebastiano.piccoli\@gmail.com>"
    ],
    "dist_name" => "Asyncore",
    "dist_version" => "0.08",
    "license" => "lgpl",
    "module_name" => "Asyncore",
    "recommends" => {},
    "recursive_test_files" => 1,
    "requires" => {
        "IO::Select" => 0,
        "IO::Socket::INET6" => 0,
        "Carp" => 0,
        "base" => 0,
        "constant" => 0,
        "integer" => 0,
        "overload" => 0,
        "perl" => "5.008001",
        "strict" => 0,
        "vars" => 0,
        "warnings" => 0
    },
    "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

my $skip_xs;
if ( grep { $_ eq '--pp' } @ARGV ) {
    $skip_xs = 1;
}
elsif ( ! $build->have_c_compiler() ) {
    $skip_xs = 1;
}

if ($skip_xs) {
    $build->build_elements(
        [ grep { $_ ne 'xs' } @{ $build->build_elements() } ] );
}
$build->create_build_script;
