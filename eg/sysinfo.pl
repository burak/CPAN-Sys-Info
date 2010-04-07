#!/usr/bin/perl -w
package Sysinfo;
use strict;
use warnings;
use lib  qw(../Sys-Info-Device-BIOS/lib);
use vars qw( $VERSION );

$VERSION = '0.10';

use constant CP_UTF8      => 65_001;
use constant KB           =>   1024;
use constant LAST_ELEMENT =>     -1;

use Carp  qw( croak );
use Number::Format;
use POSIX qw(locale_h);
use Text::Table;
use Time::Elapsed qw( elapsed );
use Sys::Info;
use Sys::Info::Constants qw(NEW_PERL);

my $LOCALE = setlocale( LC_CTYPE );

my $i    = Sys::Info->new;
my $os   = $i->os;
my $cpu  = $i->device('CPU');
my $up   = elapsed $os->tick_count;
my $NA   = 'N/A';
my $NF   = Number::Format->new( THOUSANDS_SEP => q{,}, DECIMAL_POINT => q{.} );
my %meta = $os->meta;
my $need_chcp = $os->is_winnt && $ENV{PROMPT};
my $oldcp;

run();

END {
   system chcp => $oldcp, '2>nul', '1>nul' if $need_chcp && $oldcp;
}

sub run {
   my @probe = probe();

   if ( $need_chcp ) {
      ## no critic (InputOutput::ProhibitBacktickOperators)
      chomp($oldcp = (split /:\s?/xms, qx(chcp))[LAST_ELEMENT]);
      system chcp => CP_UTF8, '2>nul', '1>nul' if $oldcp; # try to change it to unicode
      if ( NEW_PERL ) {
         my $eok = eval q{ binmode STDOUT, ':utf8'; 1; };
      }
   }
   my @titles = ( "FIELD\n=====", "VALUE\n=====");
   @titles = ( q{}, q{});

   my $tb = Text::Table->new( @titles );
   $tb->load( @probe );
   print "\n", $tb or croak "Unable to orint to STDOUT: $!";
   return;
}

sub probe {
   my @rv = eval { _probe(); };
   croak "Error fetching information: $@" if $@;
   return @rv;
}

sub _probe {
   return(
   [ 'Sys::Info Version'         => Sys::Info->VERSION                     ],
   [ 'Perl Version'              => $i->perl_long                          ],
   [ 'Host Name'                 => $os->host_name                         ],
   [ 'OS Name'                   => _os_name()                             ],
   [ 'OS Version'                => _os_version()                          ],
   [ 'OS Manufacturer'           => $meta{'manufacturer'}        || $NA    ],
   [ 'OS Configuration'          => $os->product_type            || $NA    ],
   [ 'OS Build Type'             => $meta{'build_type'}          || $NA    ],
   [ 'Running on'                => _bitness()                             ],
   [ 'Registered Owner'          => $meta{'owner'}               || $NA    ],
   [ 'Registered Organization'   => $meta{'organization'}        || $NA    ],
   [ 'Product ID'                => $meta{'product_id'}          || $NA    ],
   [ 'Original Install Date'     => _install_date()                        ],
   [ 'System Up Time'            => $up                          || $NA    ],
   [ 'System Manufacturer'       => $meta{'system_manufacturer'} || $NA    ],
   [ 'System Model'              => $meta{'system_model'}        || $NA    ],
   [ 'System Type'               => $meta{'system_type'}         || $NA    ],
   [ 'Processor(s)'              => _processors()                || $NA    ],
   [ 'BIOS Version'              => _bios_version()                        ],
   [ 'Windows Directory'         => $meta{windows_dir}           || $NA    ],
   [ 'System Directory'          => $meta{system_dir}            || $NA    ],
   [ 'Boot Device'               => $meta{'boot_device'}         || $NA    ],
   [ 'System Locale'             => $LOCALE                      || $NA    ],
   [ 'Input Locale'              => $LOCALE                      || $NA    ],
   [ 'Time Zone'                 => $os->tz                      || $NA    ],
   [ 'Total Physical Memory'     => _mb($meta{'physical_memory_total'}    )],
   [ 'Available Physical Memory' => _mb($meta{'physical_memory_available'})],
   [ 'Virtual Memory: Max Size'  => _mb($meta{'page_file_total'}          )],
   [ 'Virtual Memory: Available' => _mb($meta{'page_file_available'}      )],
   [ 'Virtual Memory: In Use'    => _vm()                                  ],
   [ 'Page File Location(s)'     => $meta{page_file_path}          || $NA  ],
   [ 'Domain'                    => $os->domain_name               || $NA  ],
   [ 'Logon Server'              => $os->logon_server              || $NA  ],

   [ 'Windows CD Key'            => $os->cdkey                     || $NA  ],
   [ 'Microsoft Office CD Key'   => _office_cdkey()                        ],
   );
}

sub _processors {
   my $rv = sprintf '%s ~%sMHz',
                    scalar($cpu->identify),
                    $cpu->speed;
   $rv =~ s{\s+}{ }xmsg;
   return $rv;
}

sub _vm {
   my $tot = $meta{'page_file_total'}     || return $NA;
   my $av  = $meta{'page_file_available'} || return $NA;
   return _mb( $tot - $av );
}

sub _mb {
   my $kb = shift || return $NA;
   my $int = sprintf '%.0f', $kb / KB;
   return sprintf '%s MB', $NF->format_number( $int );
}

sub _os_name {
   return $os->name( long => 1, edition => 1 );
}

sub _os_version {
   return $os->version . q{.} . $os->build;
}

sub _office_cdkey {
   return ($os->cdkey( office => 1 ))[0] || $NA ;
}

sub _bitness {
   my %bit = (
      cpu => $cpu->bitness || q{??},
      os  => $os->bitness  || q{??},
   );
   return "$bit{cpu}bit CPU & $bit{os}bit OS";
}

sub _install_date {
   return $meta{'install_date'} ? scalar localtime $meta{'install_date'} : $NA;
}

sub _bios_version {
   local $@;
   my $bv = eval {
               $i->device('bios')->version;
            };
   return $bv;
}

1;

__END__

=head1 NAME

sysinfo.pl - Create a list of available components in the system

=head1 DESCRIPTION

The output is identical to I<systeminfo> windows command.

=cut
