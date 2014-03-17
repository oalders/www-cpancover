use strict;
use warnings;

use FindBin;
use Path::Class qw( file );
use Test::Most;
use WWW::CPANCover;
use WWW::Mechanize;

my $uri = file( '', $FindBin::Bin, '../', 'test-data', 'cpancover.json' );

{
    # don't use cache
    my $cover = WWW::CPANCover->new(
        _uri => $uri,
        ua   => WWW::Mechanize->new,
    );

    test_contents( $cover, 'without cache' );
}

{
    # assert that cache isn't exploding
    my $cover = WWW::CPANCover->new( _uri => $uri );

    test_contents( $cover, 'with cache' );
}

sub test_contents {
    my $cover       = shift;
    my $description = shift;
    my $release     = 'ACL-Lite-0.0004';

    is_deeply(
        $cover->_current_reports,
        { $release => 1 },
        'reports are available ' . $description
    );
    ok( $cover->_has_report( $release ), 'report exists ' . $description );

    is_deeply(
        $cover->all_urls,
        { $release => "http://cpancover.com/latest/$release/index.html" },
        'all_urls ' . $description
    );

    is( $cover->report_url( $release ),
        "http://cpancover.com/latest/$release/index.html",
        'correct report_url for ' . $release
    );
    is( $cover->report_url( 'Foo' ),
        undef, 'undef report_url when not found' );
}

done_testing();
