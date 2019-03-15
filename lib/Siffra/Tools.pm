package Siffra::Tools;

use 5.014;
use strict;
use warnings;
use utf8;
use DDP;
use Data::Dumper;
use Data::Dumper::AutoEncode;
use Log::Any qw($log);
use Scalar::Util qw(blessed);

use Carp;
$Carp::Verbose = 1;

BEGIN
{
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = '0.02';
    @ISA     = qw(Exporter);

    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();

    $SIG{ __DIE__ } = sub {
        $log->info( 'Entrando em __DIE__', { package => __PACKAGE__ } );
        if ( $^S )
        {
            $log->debug( 'Entrando em __DIE__ eval {}', { package => __PACKAGE__ } );

            # We're in an eval {} and don't want log
            # this message but catch it later
            return;
        } ## end if ( $^S )

        ( my $message = $_[ 0 ] ) =~ s/\n|\r//g;
        $log->fatal( $message, { package => __PACKAGE__ } );

        die eDumper @_;    # Now terminate really
    };

    $SIG{ __WARN__ } = sub {
        p @_;
        state $count = 0;
        ( my $message = $_[ 0 ] ) =~ s/\n|\r//g;
        $log->warn( $message, { package => __PACKAGE__, count => $count++, global_phase => ${^GLOBAL_PHASE} } );
    };
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

    my $self = {};

    $self = bless( $self, ref( $class ) || $class );

    $log->info( "new", { progname => $0, pid => $$, perl_version => $], package => __PACKAGE__ } );

    return $self;
} ## end sub new

sub _initialize()
{
    my ( $self, %parameters ) = @_;
    $log->info( "_initialize", { package => __PACKAGE__ } );

    require JSON::XS;
    $self->{ json } = JSON::XS->new->utf8;
} ## end sub _initialize

sub END
{
    $log->info( "END", { package => __PACKAGE__ } );
}

=head2 C<AUTOLOAD>
 
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

sub AUTOLOAD
{
    my ( $self, @parameters ) = @_;
    our $AUTOLOAD;

    return if ( $AUTOLOAD =~ /DESTROY/ );

    #carp( qq(Não existe a sub "$AUTOLOAD"...) );
} ## end sub AUTOLOAD

sub DESTROY
{
    my ( $self, %parameters ) = @_;
    $log->info( 'DESTROY', { package => __PACKAGE__, GLOBAL_PHASE => ${^GLOBAL_PHASE} } );
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    if ( blessed( $self ) && $self->isa( __PACKAGE__ ) )
    {
        $log->alert( "DESTROY", { package => __PACKAGE__, GLOBAL_PHASE => ${^GLOBAL_PHASE}, blessed => 1 } );
    }
    else
    {
        # TODO
    }
} ## end sub DESTROY

=head2 C<getFileMD5()>
 
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

#-------------------------------------------------------------------------------
# Retorna o MD5 do arquivo
# Parametro 1 - Caminho e nome do arquivo a ser calculado
# Retorna o MD5 do arquivo informado
#-------------------------------------------------------------------------------
sub getFileMD5($)
{
    my ( $self, %parameters ) = @_;
    my $file = $parameters{ file };
    my $return;
    require Digest::MD5;
    if ( open( my $fh, $file ) )
    {
        binmode( $fh );
        $return = Digest::MD5->new->addfile( $fh )->hexdigest;
        close( $fh );
    } ## end if ( open( my $fh, $file...))

    return $return;
} ## end sub getFileMD5($)

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

