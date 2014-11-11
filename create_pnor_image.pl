#!/usr/bin/perl

use strict;
use File::Basename;

my $program_name = File::Basename::basename $0;
my $outdir = "";
my $scratch_dir = "";
my $pnor_data_dir = "";
my $pnor_filename = "";
my $payload = "";
my $hb_image_dir = "";
my $xml_layout_file = "";
my $targeting_binary_filename = "";
my $sbec_binary_filename = "";
my $sbe_binary_filename = "";

while (@ARGV > 0){
    $_ = $ARGV[0];
    chomp($_);
    $_ = &trim_string($_);
    if (/^-h$/i || /^-help$/i || /^--help$/i){
        #print help content
        usage();
        exit 0;
    }
    elsif (/^-scratch_dir/i){
        $scratch_dir = $ARGV[1] or die "Bad command line arg given: expecting a scratch dir path.\n";
        shift;
    }
    elsif (/^-outdir/i){
        $outdir = $ARGV[1] or die "Bad command line arg given: expecting a directory for output data.\n";
        shift;
    }
    elsif (/^-pnor_data_dir/i){
        $pnor_data_dir = $ARGV[1] or die "Bad command line arg given: expecting a directory containing pnor data.\n";
        shift;
    }
    elsif (/^-pnor_filename/i){
        $pnor_filename = $ARGV[1] or die "Bad command line arg given: expecting a pnor filename.\n";
        shift;
    }
    elsif (/^-hb_image_dir/i){
        $hb_image_dir = $ARGV[1] or die "Bad command line arg given: expecting an hb image dir path.\n";
        shift;
    }
    elsif (/^-xml_layout_file/i){
        $xml_layout_file = $ARGV[1] or die "Bad command line arg given: expecting an xml layout file.\n";
        shift;
    }
    elsif (/^-payload/i){
        $payload = $ARGV[1] or die "Bad command line arg given: expecting a filepath to payload binary file.\n";
        shift;
    }
    elsif (/^-targeting_binary_filename/i){
        $targeting_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a targeting binary filename.\n";
        shift;
    }
    elsif (/^-sbe_binary_filename/i){
        $sbe_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting an sbe binary filename.\n";
        shift;
    }
    elsif (/^-sbec_binary_filename/i){
        $sbec_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting an sbec binary filename.\n";
        shift;
    }
    else {
        print "Unrecognized command line arg: $_ \n";
        print "To view all the options and help text run \'$program_name -h\' \n";
        exit 1;
    }
    shift;
}

if ($outdir eq "") {
    die "-outdir <path_to_directory_for_output_files> is a required command line variable. Please run again with this parameter.\n";
}

print "scratch_dir = $scratch_dir\n";
print "pnor_data_dir = $pnor_data_dir\n";

my $build_pnor_command = "$hb_image_dir/buildpnor.pl";
$build_pnor_command .= " --pnorOutBin $pnor_filename --pnorLayout $xml_layout_file";
$build_pnor_command .= " --binFile_HBD $scratch_dir/$targeting_binary_filename";
$build_pnor_command .= " --binFile_SBE $scratch_dir/$sbe_binary_filename";
$build_pnor_command .= " --binFile_SBEC $scratch_dir/$sbec_binary_filename";
$build_pnor_command .= " --binFile_WINK $scratch_dir/p8.ref_image.hdr.bin.ecc";
$build_pnor_command .= " --binFile_HBB $scratch_dir/hostboot.header.bin.ecc";
$build_pnor_command .= " --binFile_HBI $scratch_dir/hostboot_extended.header.bin.ecc";
$build_pnor_command .= " --binFile_HBRT $scratch_dir/hostboot_runtime.header.bin.ecc";
$build_pnor_command .= " --binFile_HBEL $scratch_dir/hbel.bin.ecc";
$build_pnor_command .= " --binFile_GUARD $scratch_dir/guard.bin.ecc";
$build_pnor_command .= " --binFile_PAYLOAD $payload";
$build_pnor_command .= " --binFile_NVRAM $scratch_dir/nvram.bin.ecc";
$build_pnor_command .= " --binFile_MVPD $scratch_dir/mvpd_fill.bin.ecc";
$build_pnor_command .= " --binFile_DJVPD $scratch_dir/djvpd_fill.bin.ecc";
$build_pnor_command .= " --binFile_CVPD $scratch_dir/cvpd.bin.ecc";
$build_pnor_command .= " --binFile_ATTR_TMP $scratch_dir/attr_tmp.bin.ecc";
$build_pnor_command .= " --binFile_ATTR_PERM $scratch_dir/attr_perm.bin.ecc";
$build_pnor_command .= " --fpartCmd \"fpart\"";
$build_pnor_command .= " --fcpCmd \"fcp\"";
print "###############################";
run_command("$build_pnor_command");

#END MAIN
#-------------------------------------------------------------------------
sub usage {


print <<"ENDUSAGE";


ENDUSAGE

;
}


sub parse_config_file {

}


#trim_string takes one string as input, trims leading and trailing whitespace
# before returning that string
sub trim_string {
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

sub run_command {
    my $command = shift;
    print "$command\n";
    my $rc = system($command);
    if ($rc !=0 ){
        die "Error running command: $command. Nonzero return code of ($rc) returned.\n";
    }
    return $rc;
}
