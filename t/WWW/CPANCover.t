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
        $cover->current_reports,
        { 'ACL-Lite-0.0004' => 1 },
        'reports are available ' . $description
    );
    ok( $cover->has_report( 'ACL-Lite-0.0004' ),
        'report exists ' . $description
    );
}

done_testing();
