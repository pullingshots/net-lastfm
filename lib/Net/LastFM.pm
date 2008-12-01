package Net::LastFM;
use Moose;
use MooseX::StrictConstructor;
use Digest::MD5 qw(md5_hex);
use LWP::UserAgent;
use URI::QueryParam;
use XML::Simple qw(:strict);
our $VERSION = '0.32';

has 'api_key' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'api_secret' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'ua' => (
    is       => 'rw',
    isa      => 'LWP::UserAgent',
    required => 0,
    default  => sub {
        my $ua = LWP::UserAgent->new;
        $ua->agent( 'Net::LastFM/' . $VERSION );
        $ua->env_proxy;
        return $ua;
    }
);

my $ROOT = 'http://ws.audioscrobbler.com/2.0/';

sub request {
    my ( $self, %conf ) = @_;
    my $ua = $self->ua;

    $conf{api_key} = $self->api_key;
    my $uri = URI->new('http://ws.audioscrobbler.com/2.0/');

    foreach my $key ( keys %conf ) {
        my $value = $conf{$key};
        $uri->query_param( $key, $value );
    }

    my $request = HTTP::Request->new( 'GET', $uri );

    my $response = $ua->request($request);

    my $data = XMLin( $response->content, ForceArray => 0, KeyAttr => [] );

    if ( $data->{status} eq 'ok' ) {
        return $data;
    } else {
        my $code    = $data->{error}->{code};
        my $content = $data->{error}->{content};
        confess "$code: $content";
    }
}

sub request_signed {
    my ( $self, %conf ) = @_;
    $conf{api_key} = $self->api_key;

    my $to_hash = '';
    foreach my $key ( sort keys %conf ) {
        my $value = $conf{$key};
        $to_hash .= $key . $value;
    }
    $to_hash .= $self->api_secret;
    $conf{api_sig} = md5_hex($to_hash);

    return $self->request(%conf);
}

1;
