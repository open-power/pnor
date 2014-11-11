#!/usr/bin/perl

use strict;
use File::Basename;

#my $ecc_tool_dir = "/opt/mcp/shared/fr_FLD8-1-20140528/opt/fsp/usr/bin"; #wh_todo

my $op_target_dir = "";
my $hb_image_dir = "";
my $scratch_dir = "";
my $hb_binary_dir = "";
my $targeting_binary_filename = "";
my $targeting_binary_source = "";
my $sbe_binary_filename = "";
my $sbec_binary_filename = "";

while (@ARGV > 0){
    $_ = $ARGV[0];
    chomp($_);
    $_ = &trim_string($_);
    if (/^-h$/i || /^-help$/i || /^--help$/i){
        usage(); #print help content
        exit 0;
    }
    elsif (/^-op_target_dir/i){
        $op_target_dir = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-hb_image_dir/i){
        $hb_image_dir = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-scratch_dir/i){
        $scratch_dir = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-hb_binary_dir/i){
        $hb_binary_dir = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-targeting_binary_filename/i){
        $targeting_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-targeting_binary_source/i){
        $targeting_binary_source = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-sbe_binary_filename/i){
        $sbe_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    elsif (/^-sbec_binary_filename/i){
        $sbec_binary_filename = $ARGV[1] or die "Bad command line arg given: expecting a config type.\n";
        shift;
    }
    else {
        print "Unrecognized command line arg: $_ \n";
        #print "To view all the options and help text run \'$program_name -h\' \n";
        exit 1;
    }
    shift;
}

#Pad Targeting binary to 4k page size, then add ECC data
run_command("dd if=$op_target_dir/$targeting_binary_source of=$scratch_dir/$targeting_binary_source ibs=4k conv=sync");
run_command("ecc --inject $scratch_dir/$targeting_binary_source --output $scratch_dir/$targeting_binary_filename --p8");

run_command("echo \"00000000001800000000000008000000000000000007EF80\" | xxd -r -ps - $scratch_dir/sbe.header");
run_command("echo -en VERSION\\\\0 > $scratch_dir/hostboot.sha.bin");
run_command("sha512sum $hb_image_dir/img/hostboot.bin | awk \'{print \$1}\' | xxd -pr -r >> $scratch_dir/hostboot.sha.bin");
run_command("dd if=$scratch_dir/hostboot.sha.bin of=$scratch_dir/secureboot.header ibs=4k conv=sync");
run_command("dd if=/dev/zero of=$scratch_dir/hbb.footer count=1 bs=128K");
run_command("cat $scratch_dir/sbe.header $scratch_dir/secureboot.header $hb_image_dir/img/hostboot.bin $scratch_dir/hbb.footer > $scratch_dir/hostboot.stage.bin");
run_command("head -c 524288 $scratch_dir/hostboot.stage.bin > $scratch_dir/hostboot.header.bin");

run_command("ecc --inject $hb_image_dir/img/hostboot.bin --output $scratch_dir/hostboot.bin.ecc --p8");
run_command("ecc --inject $scratch_dir/hostboot.header.bin --output $scratch_dir/hostboot.header.bin.ecc --p8");
run_command("dd if=$hb_image_dir/img/hostboot_extended.bin of=$scratch_dir/hostboot_extended.bin.pad ibs=4k count=1280 conv=sync");
run_command("ecc --inject $scratch_dir/hostboot_extended.bin.pad --output $scratch_dir/hostboot_extended.bin.ecc --p8");

run_command("echo -en VERSION\\\\0 > $scratch_dir/hostboot_runtime.sha.bin");
run_command("sha512sum $hb_image_dir/img/hostboot_runtime.bin | awk \'{print \$1}\' | xxd -pr -r >> $scratch_dir/hostboot_runtime.sha.bin");
run_command("dd if=$scratch_dir/hostboot_runtime.sha.bin of=$scratch_dir/hostboot.temp.bin ibs=4k conv=sync");
run_command("cat $hb_image_dir/img/hostboot_runtime.bin >> $scratch_dir/hostboot.temp.bin");
run_command("dd if=$scratch_dir/hostboot.temp.bin of=$scratch_dir/hostboot_runtime.header.bin ibs=2048K conv=sync");
run_command("ecc --inject $scratch_dir/hostboot_runtime.header.bin --output $scratch_dir/hostboot_runtime.header.bin.ecc --p8");

run_command("echo -en VERSION\\\\0 > $scratch_dir/hostboot_extended.sha.bin");
run_command("sha512sum $hb_image_dir/img/hostboot_extended.bin | awk \'{print \$1}\' | xxd -pr -r >> $scratch_dir/hostboot_extended.sha.bin");
run_command("dd if=$scratch_dir/hostboot_extended.sha.bin of=$scratch_dir/hostboot.temp.bin ibs=4k conv=sync");
run_command("cat $hb_image_dir/img/hostboot_extended.bin >> $scratch_dir/hostboot.temp.bin");
run_command("dd if=$scratch_dir/hostboot.temp.bin of=$scratch_dir/hostboot_extended.header.bin ibs=5120k conv=sync");
run_command("ecc --inject $scratch_dir/hostboot_extended.header.bin --output $scratch_dir/hostboot_extended.header.bin.ecc --p8");

#Create blank binary file for HB Errorlogs (HBEL) Partition
run_command("dd if=/dev/zero bs=128K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/hbel.bin.ecc --p8");\

#Create blank binary file for GUARD Data (GUARD) Partition
run_command("dd if=/dev/zero bs=16K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/guard.bin.ecc --p8");

#Create blank binary file for NVRAM Data (NVRAM) Partition
run_command("dd if=/dev/zero bs=512K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/nvram.bin.ecc --p8");

#Create blank binary file for MVPD Partition
run_command("dd if=/dev/zero bs=512K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/mvpd_fill.bin.ecc --p8");

#Create blank binary file for DJVPD Partition
run_command("dd if=/dev/zero bs=256K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/djvpd_fill.bin.ecc --p8");

#Add ECC Data to CVPD Data (CVPD) Partition
run_command("ecc --inject $hb_binary_dir/cvpd.bin --output $scratch_dir/cvpd.bin.ecc --p8");

#Create blank binary file for ATTR_TMP Partition
run_command("dd if=/dev/zero bs=28K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/attr_tmp.bin.ecc --p8");

#Create blank binary file for ATTR_PERM Partition
run_command("dd if=/dev/zero bs=28K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/attr_perm.bin.ecc --p8");

#Create blank binary file for OCC Partition
run_command("dd if=/dev/zero bs=908K count=1 | tr \"\\000\" \"\\377\" > $scratch_dir/hostboot.temp.bin");
run_command("ecc --inject $scratch_dir/hostboot.temp.bin --output $scratch_dir/occ.bin.ecc --p8");

#Copy Binary Data files for consistency
run_command("cp $hb_binary_dir/$sbec_binary_filename $scratch_dir/");
run_command("cp $hb_binary_dir/$sbe_binary_filename $scratch_dir/");
run_command("cp $hb_binary_dir/p8.ref_image.hdr.bin.ecc $scratch_dir/");

#END MAIN
#-------------------------------------------------------------------------





############# HELPER FUNCTIONS #################################################
# Function to first print, and then run a system command, erroring out if the
#  command does not complete successfully
sub run_command {
    my $command = shift;
    print "$command\n";
    my $rc = system($command);
    if ($rc !=0 ){
        die "Error running command: $command. Nonzero return code of ($rc) returned.\n";
    }
    return $rc;
}

# Function to remove leading and trailing whitespeace before returning that string
sub trim_string {
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}
