package Validate::Plugin::version;

use strict;

sub new {
    my $classname = shift;
    my $self      = {};
    bless( $self, $classname );
    $self->{validate} = shift;
    return $self;
}

sub run {
    my $self     = shift;
    my $validate = $self->{validate};
    my $config   = $validate->{config};

    my %config = %{$config};
    my $site   = $config{"site"}{"name"};

    my $expect = $self->get_version("http://test-ipv6.com/version.html");
    my $found  = $self->get_version("http://$site/version.html");

    my $notes = "Checked http://$site/version.html against http://test-ipv6.com/version.html";

    if ( $found !~ /\d+/ ) {
        $notes = <<"EOF";
Could not identify the Revision number of your mirror.
Please make sure that you're up to date (at least version $expect).

* http://$site/version.html
* http://code.google.com/p/falling-sky/wiki/InstallContent
* http://code.google.com/p/falling-sky/wiki/UpgradeFromSvn
EOF
        return { status => "bad", expect => $expect, found => $found, notes => $notes };
    }

    if ( $found ne $expect ) {
        $notes = <<"EOF";
UPGRADE_NEEDED (from $found to $expect)

We found you are running version $found of the mirror site;
we were hoping you were running version $expect or newer.

Please refresh the content portion of your mirror.  Instructions
for this are online; as well as instructions on how to automate
this task with rsync and cron.

* http://$site/version.html
* http://code.google.com/p/falling-sky/wiki/InstallContent    
EOF
        return { status => "bad", expect => $expect, found => $found, notes => $notes, brief=>"upgrade $found to $expect" };
    }
    return { status =>"ok", expect => $expect, found => $found, notes => $notes };
} ## end sub run

sub get_version {
    my $self = shift;
    my $url  = shift;
    $DB::single = 1;
    my ( $content, $headers ) = $self->{validate}->curl( $url, "--get" );
      if ( $content =~ m#^Revision: (\d+)#ms ) {
        return $1;
    } else {
        die $content;
        return "not found";
    }

}

1;
