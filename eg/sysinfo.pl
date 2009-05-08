#!/usr/bin/perl -w
package sysinfo;
use strict;
use lib qw(../Sys-Info-Device-BIOS/lib);
use vars qw( $VERSION );
use POSIX qw(locale_h);
use Sys::Info;
use Sys::Info::Constants qw(NEW_PERL);
use Time::Elapsed qw( elapsed );
use Number::Format;
use Text::Table;

$VERSION = '0.10';

my $LOCALE = setlocale( LC_CTYPE );

my $i    = Sys::Info->new;
my $os   = $i->os;
my $cpu  = $i->device('CPU');
my $up   = elapsed $os->tick_count;
my $NA   = 'N/A';
my $NF   = Number::Format->new( THOUSANDS_SEP => q{,}, DECIMAL_POINT => q{.} );
my %meta = $os->meta;
my $need_chcp = $os->is_winnt && $ENV{PROMPT};

my @probe;

my %bit = (
   cpu => $cpu->bitness,
   os  => $os->bitness,
);
map { $bit{$_} ||= '??' } keys %bit;

@probe = eval {(
   [ "Sys::Info Version"         => Sys::Info->VERSION                     ],
   [ "Perl Version"              => $i->perl_long                          ],
   [ "Host Name"                 => $os->host_name                         ],
   [ "OS Name"                   => $os->name( long => 1, edition => 1 )   ],
   [ "OS Version"                => $os->version . '.' . $os->build        ],
   [ "OS Manufacturer"           => $meta{'manufacturer'}        || $NA    ],
   [ "OS Configuration"          => $os->product_type            || $NA    ],
   [ "OS Build Type"             => $meta{'build_type'}          || $NA    ],
   [ "Running on"                => "$bit{cpu}bit CPU & $bit{os}bit OS"    ],
   [ "Registered Owner"          => $meta{'owner'}               || $NA    ],
   [ "Registered Organization"   => $meta{'organization'}        || $NA    ],
   [ "Product ID"                => $meta{'product_id'}          || $NA    ],
   [ "Original Install Date"     => scalar localtime $meta{'install_date'} ],
   [ "System Up Time"            => $up                          || $NA    ],
   [ "System Manufacturer"       => $meta{'system_manufacturer'} || $NA    ],
   [ "System Model"              => $meta{'system_model'}        || $NA    ],
   [ "System Type"               => $meta{'system_type'}         || $NA    ],
   [ "Processor(s)"              => processors()                 || $NA    ],
   [ "BIOS Version"              => $i->device('bios')->version  || $NA    ],
   [ "Windows Directory"         => $meta{windows_dir}           || $NA    ],
   [ "System Directory"          => $meta{system_dir}            || $NA    ],
   [ "Boot Device"               => $meta{'boot_device'}         || $NA    ],
   [ "System Locale"             => $LOCALE                      || $NA    ],
   [ "Input Locale"              => $LOCALE                      || $NA    ],
   [ "Time Zone"                 => $os->tz                      || $NA    ],
   [ "Total Physical Memory"     => mb($meta{'physical_memory_total'}    ) ],
   [ "Available Physical Memory" => mb($meta{'physical_memory_available'}) ],
   [ "Virtual Memory: Max Size"  => mb($meta{'page_file_total'}          ) ],
   [ "Virtual Memory: Available" => mb($meta{'page_file_available'}      ) ],
   [ "Virtual Memory: In Use"    => vm()                                   ],
   [ "Page File Location(s)"     => $meta{page_file_path}          || $NA  ],
   [ "Domain"                    => $os->domain_name               || $NA  ],
   [ "Logon Server"              => $os->logon_server              || $NA  ],

   [ "Windows CD Key"            => $os->cdkey                     || $NA  ],
   [ "Microsoft Office CD Key"   => ($os->cdkey( office => 1 ))[0] || $NA  ],
)};

die "Error fetching information: $@" if $@;

my $oldcp;
if ( $need_chcp ) {
   chomp($oldcp = (split /:\s?/, qx(chcp))[-1]);
   system(chcp => 65001, '2>nul', '1>nul') if $oldcp; # try to change it to unicode
   eval q{ binmode STDOUT, ':utf8' } if NEW_PERL;
}

END {
   system(chcp => $oldcp, '2>nul', '1>nul') if $need_chcp && $oldcp;
}

my @titles = ( "FIELD\n=====", "VALUE\n=====");
@titles = ( "", "");

my $tb = Text::Table->new( @titles );
   $tb->load( @probe );
print "\n";
print $tb;

sub processors {
   my $rv = sprintf "%s ~%sMHz",
                    scalar($cpu->identify),
                    $cpu->speed;
   $rv =~ s{\s+}{ }sg;
   $rv;
}

sub vm {
   my $tot = $meta{'page_file_total'}     || return $NA;
   my $av  = $meta{'page_file_available'} || return $NA;
   return mb( $tot - $av );
}

sub mb {
   my $kb = shift || return $NA;
   my $int = sprintf '%.0f', $kb / 1024;
   return sprintf '%s MB', $NF->format_number( $int );
}


__END__

=head1 NAME

sysinfo.pl - Create a list of available components in the system

=head1 DESCRIPTION

The output is identical to I<systeminfo> windows command.

=cut
