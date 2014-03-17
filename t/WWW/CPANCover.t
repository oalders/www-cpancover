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

    is_deeply(
        $cover->_current_reports,
        { 'ACL-Lite-0.0004' => 1 },
        'reports are available ' . $description
    );
    ok( $cover->_has_report( 'ACL-Lite-0.0004' ),
        'report exists ' . $description
    );

    is_deeply(
        $cover->all_urls,
        {   'ACL-Lite-0.0004' =>
                'http://cpancover.com/latest/ACL-Lite-0.0004/index.html'
        },
        'all_urls ' . $description
    );
}

done_testing();
