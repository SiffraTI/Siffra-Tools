package Siffra::Tools;

use 5.014;
use strict;
use warnings;
use Carp;
use utf8;
use Data::Dumper;
use DDP;
use Log::Any qw($log);
use Scalar::Util qw(blessed);
$Carp::Verbose = 1;

$| = 1;    #autoflush

use constant {
    FALSE => 0,
    TRUE  => 1,
    DEBUG => $ENV{ DEBUG } // 0,
};

my %driverConnections = (
    pgsql => {
        module => 'DBD::Pg',
        dsn    => 'DBI:Pg(AutoCommit=>1,RaiseError=>1,PrintError=>0):dbname=%s;host=%s;port=%s',
    },
    mysql => {
        module => 'DBD::mysql',
    },
    sqlite => {
        module => 'DBD::SQLite',
    },
);

BEGIN
{
    binmode( STDOUT, ":encoding(UTF-8)" );
    binmode( STDERR, ":encoding(UTF-8)" );

    require Siffra::Base;
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = '0.05';
    @ISA     = qw(Siffra::Base Exporter);

    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
} ## end BEGIN

#################### subroutine header begin ####################

=head2 sample_function

 Usage     : How to use this function/method
 Purpose   : What it does
 Returns   : What it returns
 Argument  : What it wants to know
 Throws    : Exceptions and other anomolies
 Comment   : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.

See Also   :

=cut

#################### subroutine header end ####################

=head2 C<new()>

  Usage     : $self->block_new_method() within text_pm_file()
  Purpose   : Build 'new()' method as part of a pm file
  Returns   : String holding sub new.
  Argument  : $module: pointer to the module being built
              (as there can be more than one module built by EU::MM);
              for the primary module it is a pointer to $self
  Throws    : n/a
  Comment   : This method is a likely candidate for alteration in a subclass,
              e.g., pass a single hash-ref to new() instead of a list of
              parameters.

=cut

sub new
{
    my ( $class, %parameters ) = @_;
    $log->debug( "new", { progname => $0, pid => $$, perl_version => $], package => __PACKAGE__ } );

    my $self = $class->SUPER::new( %parameters );

    return $self;
} ## end sub new

sub _initialize()
{
    my ( $self, %parameters ) = @_;
    $log->debug( "_initialize", { package => __PACKAGE__ } );

    require JSON::XS;
    $self->{ json } = JSON::XS->new->utf8;
} ## end sub _initialize

sub END
{
    $log->debug( "END", { package => __PACKAGE__ } );
    eval { $log->{ adapter }->{ dispatcher }->{ outputs }->{ Email }->flush; };
}

sub DESTROY
{
    my ( $self, %parameters ) = @_;
    $log->debug( 'DESTROY', { package => __PACKAGE__, GLOBAL_PHASE => ${^GLOBAL_PHASE}, blessed => FALSE } );
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    if ( blessed( $self ) && $self->isa( __PACKAGE__ ) )
    {
        $log->debug( "DESTROY", { package => __PACKAGE__, GLOBAL_PHASE => ${^GLOBAL_PHASE}, blessed => TRUE } );
    }
    else
    {
        # TODO
    }
} ## end sub DESTROY

=head2 C<connectDB()>
=cut

sub connectDB()
{
    my ( $self, %parameters ) = @_;
    $log->debug( "connectDB", { package => __PACKAGE__ } );

    my ( $database, $host, $password, $port, $username, $connection );

    if ( %parameters )
    {
        $connection = $parameters{ connection };
        $database   = $parameters{ database };
        $host       = $parameters{ host };
        $password   = $parameters{ password };
        $port       = $parameters{ port };
        $username   = $parameters{ username };
    } ## end if ( %parameters )
    elsif ( defined $self->{ configurations }->{ database } )
    {
        $connection = $self->{ configurations }->{ database }->{ connection };
        $database   = $self->{ configurations }->{ database }->{ database };
        $host       = $self->{ configurations }->{ database }->{ host };
        $password   = $self->{ configurations }->{ database }->{ password };
        $port       = $self->{ configurations }->{ database }->{ port };
        $username   = $self->{ configurations }->{ database }->{ username };
    } ## end elsif ( defined $self->{ ...})
    else
    {
        $log->error( "Tentando conectar mas sem configuração de DB..." );
        return FALSE;
    }

    my $driverConnection = $driverConnections{ lc $connection };
    if ( $driverConnection )
    {
        eval {
            require DBI;
            require "$driverConnection->{ module }";
        };

        my $dsn = sprintf( $driverConnection->{ dsn }, $database, $host, $port );
        my ( $scheme, $driver, $attr_string, $attr_hash, $driver_dsn ) = DBI->parse_dsn( $dsn ) or die "Can't parse DBI DSN '$dsn'";
        my $data_source = "$scheme:$driver:$driver_dsn";
        $self->{ database }->{ connection } = eval { DBI->connect( $data_source, $username, $password, $attr_hash ); };

        if ( $@ )
        {
            $log->error( "Erro ao conectar ao banco [ $data_source ] [ $username\@$host:$port ]." );
            $log->error( @_ );
            return FALSE;
        } ## end if ( $@ )
    } ## end if ( $driverConnection...)
    else
    {
        $log->error( "Connection [ $connection ] não existe configuração..." );
        return FALSE;
    }

    return $self->{ database }->{ connection };
} ## end sub connectDB

=head2 C<begin_work()>
=cut

sub begin_work()
{
    my ( $self, %parameters ) = @_;
    if ( !defined $self->{ database }->{ connection } )
    {
        $log->error( "Tentando começar uma transação sem uma conexão com DB..." );
        return FALSE;
    }
    my $rc = $self->{ database }->{ connection }->begin_work or die $self->{ database }->{ connection }->errstr;
    return $rc;
} ## end sub begin_work

=head2 C<commit()>
=cut

sub commit()
{
    my ( $self, %parameters ) = @_;
    if ( !defined $self->{ database }->{ connection } )
    {
        $log->error( "Tentando commitar uma transação sem uma conexão com DB..." );
        return FALSE;
    }
    my $rc = $self->{ database }->{ connection }->commit or die $self->{ database }->{ connection }->errstr;
    return $rc;
} ## end sub commit

=head2 C<rollback()>
=cut

sub rollback()
{
    my ( $self, %parameters ) = @_;
    if ( !defined $self->{ database }->{ connection } )
    {
        $log->error( "Tentando reverter uma transação sem uma conexão com DB..." );
        return FALSE;
    }
    my $rc = $self->{ database }->{ connection }->rollback or die $self->{ database }->{ connection }->errstr;
    return $rc;
} ## end sub rollback

=head2 C<prepareQuery()>
=cut

sub prepareQuery
{
    my ( $self, %parameters ) = @_;
    my $sql = $parameters{ sql };

    my $sth = $self->{ database }->{ connection }->prepare( $sql ) or die $self->{ database }->{ connection }->errstr;
    return $sth;
} ## end sub prepareQuery

=head2 C<doQuery()>
=cut

sub doQuery
{
    my ( $self, %parameters ) = @_;
    my $sql = $parameters{ sql };

    my $sth = $self->{ database }->{ connection }->do( $sql ) or die $self->{ database }->{ connection }->errstr;
    return $sth;
} ## end sub doQuery

=head2 C<executeQuery()>
=cut

sub executeQuery()
{
    my ( $self, %parameters ) = @_;
    my $sql = $parameters{ sql };

    $self->connectDB() unless ( defined( $self->{ database }->{ connection } ) );

    my $sth = $self->prepareQuery( sql => $sql );
    my $res = $sth->execute();

    return $sth;
} ## end sub executeQuery

=head2 C<teste()>
=cut

sub teste()
{
    my ( $self, %parameters ) = @_;

    $self->{ configurations }->{ teste } = 'LALA';
    return $self;
} ## end sub teste

=head2 C<getFileMD5()>
-------------------------------------------------------------------------------
 Retorna o MD5 do arquivo
 Parametro 1 - Caminho e nome do arquivo a ser calculado
 Retorna o MD5 do arquivo informado
-------------------------------------------------------------------------------
=cut

sub getFileMD5()
{
    my ( $self, %parameters ) = @_;
    my $file = $parameters{ file };

    return FALSE unless ( -e $file );

    my $return;

    eval { require Digest::MD5; };
    if ( $@ )
    {
        $log->error( 'Package Digest::MD5 não encontrado...' );
        return FALSE;
    }

    if ( open( my $fh, $file ) )
    {
        binmode( $fh );
        $return = Digest::MD5->new->addfile( $fh )->hexdigest;
        close( $fh );
    } ## end if ( open( my $fh, $file...))
    else
    {
        $log->error( "Não foi possível abrir o arquivo [ $file ]..." );
    }

    return $return;
} ## end sub getFileMD5

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module.
## You better edit it!

=encoding UTF-8


=head1 NAME

Siffra::Tools - Module abstract (<= 44 characters) goes here

=head1 SYNOPSIS

  use Siffra::Tools;
  blah blah blah


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Luiz Benevenuto
    CPAN ID: LUIZBENE
    Siffra TI
    luiz@siffra.com.br
    https://siffra.com.br

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################

1;

# The preceding line will help the module return a true value

