use strict;
use warnings;

package WWW::CPANCover;

use Carp qw( croak );
use CHI;
use Cpanel::JSON::XS;
use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw( HashRef );
use MooseX::Types::URI qw( Uri );
use Try::Tiny;
use WWW::Mechanize::Cached::GZip;

has cache => (
    is      => 'ro',
    isa     => 'CHI::Driver::SharedMem',
    lazy    => 1,
    default => sub {
        my $cache = CHI->new(
            driver     => 'SharedMem',
            expires_in => '1d',
            size       => 256 * 1024,
            shmkey     => 42,
        );
    },
);

has current_reports => (
    is      => 'ro',
    isa     => HashRef,
    traits  => ['Hash'],
    handles => { has_report => 'get', },
    lazy    => 1,
    builder => '_build_current_reports',
);

has ua => (
    is      => 'ro',
    isa     => 'WWW::Mechanize',
    lazy    => 1,
    builder => '_build_ua',
);

has _uri => (
    is      => 'ro',
    isa     => Uri,
    coerce  => 1,
    default => 'http://cpancover.com/latest/cpancover.json',
);

sub _build_ua {
    my $self = shift;
    return WWW::Mechanize::Cached::GZip->new(
        autocheck => 0,
        cache     => $self->cache
    );
}

sub _build_current_reports {
    my $self = shift;
    my $res  = $self->ua->get( $self->_uri );
    if ( !$res->is_success ) {
        croak 'Report list not found: ' . $res->status;
    }

    my $reports = {};
    try {
        $reports = decode_json( $res->content );
    }
    catch {
        croak 'cannot decode report: ' . $_;
    };

    return $reports;
}

sub report_url {
    my $self = shift;
    my $name = shift;

    my $report = $self->has_report( $name );
    return if !$report;
    return "http://cpancover.com/latest/$name/index.html";
}

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: Easy access to the CPANCover API

=pod

=head1 NAME

WWW::CPANCover

=head1 DESCRIPTION

This module is a basic wrapper around the CPANCover API.  By default it caches
the JSON returned by CPANCover in order to speed up subsequent requests.

=head1 SYNOPSIS

    use WWW::CPANCover;

    my $cover = WWW::CPANCover->new;
    say $cover->report_url( 'ACL-Lite-0.0004' );
    # returns http://cpancover.com/latest/ACL-Lite-0.0004/index.html

=head1 CONSTRUCTOR ARGUMENTS

=head2 cache

You may provide your own caching mechanism, provided it's a CHI object.

    my $cache = CHI->new(
        driver     => 'SharedMem',
        expires_in => '1d',
        size       => 256 * 1024,
        shmkey     => 42,
    );

    my $cover = WWW::CPANCover->new(
        cache => $cache
    );

=head2 ua

You may provide your own UserAgent object, as long as it provides a get()
method.  You may want to do this, for instance, to bypass the caching layer.

    my $cover = WWW::CPANCover->new(
        ua => WWW::Mechanize->new
    );


=head2 report_url( $release )

Requires a release name as its sole argument.  Returns undef if no report URL
exists for this release.

    my $cover = WWW::CPANCover->new;
    say $cover->report_url( 'ACL-Lite-0.0004' );
    # returns http://cpancover.com/latest/ACL-Lite-0.0004/index.html

=cut
