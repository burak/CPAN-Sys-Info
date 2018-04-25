
# BEGIN dynamic

# This section is used/injected by dzil and not to be executed as a
# standalone program

# copy-paste from Sys::Info::Constants
BEGIN {
    if ( ! defined &OSID ) {
        my %OS = (
            MSWin32  => 'Windows',
            MSWin64  => 'Windows',
            linux    => 'Linux',
            darwin   => 'OSX',
        );
        $OS{$_} = 'BSD' for qw( freebsd openbsd netbsd );
        my $ID = $OS{ $^O } || 'Unknown';
        *OSID = sub () { "$ID" }
    }
}

requires( 'Sys::Info::Driver::' . OSID() => '0.78');

# END dynamic
