use strict;
use warnings;

package WWW::CPANCover;

use CHI::Driver::SharedMem; # for cpanfile
use CHI;
use Carp qw( croak );
use Cpanel::JSON::XS;
use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw( HashRef );
use MooseX::Types::URI qw( Uri );
use Try::Tiny;
use WWW::Mechanize::Cached 1.43; # for cpanfile
use WWW::Mechanize::Cached::GZip;

has _current_reports => (
    is      => 'ro',
    isa     => HashRef,
    traits  => ['Hash'],
    handles => { _has_report => 'get', _all_releases => 'keys', },
    lazy    => 1,
    builder => '_build_current_reports',
);

has _uri => (
    is      => 'ro',
    isa     => Uri,
    coerce  => 1,
    default => 'http://cpancover.com/latest/cpancover.json',
);

has all_urls => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_all_urls',
);

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

has ua => (
    is      => 'ro',
    isa     => 'WWW::Mechanize',
    lazy    => 1,
    builder => '_build_ua',
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

sub _build_all_urls {
    my $self = shift;
    my %urls = ();
    foreach my $release ( $self->_all_releases ) {
        $urls{$release} = $self->report_url( $release );
    }
    return \%urls;
}

sub report_url {
    my $self = shift;
    my $name = shift;

    my $report = $self->_has_report( $name );
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

You may supply your own UserAgent object, as long as it provides a get()
method.  You may want to do this, for instance, to bypass the caching layer.

    my $cover = WWW::CPANCover->new(
        ua => WWW::Mechanize->new
    );


=head1 METHODS

=head2 report_url( $release )

Requires a release name as its sole argument.  Returns undef if no report URL
exists for this release.

    my $cover = WWW::CPANCover->new;
    say $cover->report_url( 'ACL-Lite-0.0004' );
    # returns http://cpancover.com/latest/ACL-Lite-0.0004/index.html

=head2 all_urls

Returns a HashRef of all available reports, keyed on release name with the
appropriate URLs as the values.

=cut
