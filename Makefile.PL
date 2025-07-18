use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;


use File::Spec::Functions;
use autodie;

my $PM_File = catfile(qw(lib Config INI RefVars.pm));

open(my $h, '<', $PM_File);
my $Version;
foreach my $line (<$h>) {
  if ($line =~ /\bour\s+\$VERSION\s+.*?["']([^"']+)["']/) {
    $Version = $1;
    last;
  }
}
close($h);
die("VERSION not found in $PM_File") if !$Version;


my %WriteMakefileArgs = (
    NAME             => 'Config::INI::RefVars',
    AUTHOR           => q{Abdul al Hazred <451@gmx.eu>},
    VERSION_FROM     => 'lib/Config/INI/RefVars.pm',
    ABSTRACT_FROM    => 'lib/Config/INI/RefVars.pm',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    PREREQ_PM => {
        'strict' => 0,
        'warnings' => 0,
        'feature'  => 0,
        'constant' => 0,
        'Carp'     => 0,
        'File::Spec::Functions' => 0,
        'Config' => 0,
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        dynamic_config => 0,
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/AAHAZRED/perl-Config-INI-RefVars.git',
                web  => 'https://github.com/AAHAZRED/perl-Config-INI-RefVars',
            },
        },
        bugtracker => {
            web => 'https://github.com/AAHAZRED/perl-Config-INI-RefVars/issues'
        },
        provides => { 'Text::Table::Read::RelationOn::Tiny' => {file => $PM_File,
                                                                version => $Version
                                                               },
                    },
    },
    TEST_REQUIRES => {
        'strict' => 0,
        'warnings' => 0,
        'constant' => 0,
        'File::Spec::Functions' => 0,
        'Config' => 0,
        'ExtUtils::MakeMaker' => 0,
        'Test::Simple' => '0.98',
        'TAP::Harness' => '3.26',
        'Test::More'  => '0.98',
        'Test::Fatal' => '0.010',
        'Test::Warn' => '0.37',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', DIST_CP => 'cp',
               PREOP => 'perl tools/pm_filter_simple.pl $(DISTVNAME)'
    },
    clean => { FILES => 'Config-INI-RefVars-*' },
);

if ($ENV{AAHAZRED_PERL_DEVEL}) {
  $WriteMakefileArgs{PM_FILTER} = 'perl tools/pm_filter_simple.pl';
}

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
