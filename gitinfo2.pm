# Copyright 2018 Raphaël P. Barazzutti
# 
# GitInfo2LatexMk - v0.2.1
# Inspired by Brent Longborough's update-git.sh (part of gitinfo2 LaTeX package)
# 
# The original update-git.sh is supposed to be "hooked" to some git events (such that
# Post-{commit,checkout,merge}).
# Although this approach is elegant, I find a bit too intrusive and complicated
# to maintain.
#
# This Perl variant makes sense for latexmk users. The only requirement is to add
# the following line into the .latexmkrc file that lays in the root of your 
# LaTeX project (create it, if absent).
# 
# do './gitinfo2.pm'
# 
# That's it! Now it'd work!

sub git_info_2 {
    
    # get file content as a string
    my $get_file_content = sub {   
        my ($f)= @_;

        # do not separate the reads per line
        local $/ = undef;

        open FILE, $f or return "";
        $string = <FILE>;

        close FILE;
        return $string;
    };

    # compare two files`
    my $cmp = sub {
        my($a,$b) = @_;

        return $get_file_content->($a) ne $get_file_content->($b);
    };

    my $RELEASE_MATCHER = "[0-9]*.*";

    if(%GI2TM_OPTIONS){        
        if(exists $GI2TM_OPTIONS{"RELEASE_MATCHER"}){
            $RELEASE_MATCHER = $GI2TM_OPTIONS{"RELEASE_MATCHER"};
        }
    }

    my $GIN = ".git/gitHeadInfo.gin";
    my $NGIN = "$GIN.new";

    if(length(`git status --porcelain`) == 0){
        # Get the first tag found in the history from the current HEAD
        my $FIRSTTAG = `git describe --tags --always --dirty='-*'`;
        chop($FIRSTTAG);

        # Get the first tag in history that looks like a Release
        my $RELTAG = `git describe --tags --long --always --dirty='-*' --match '$RELEASE_MATCHER'`;
        chop($RELTAG);

        # Hoover up the metadata
        my $metadata =`git --no-pager log -1 --date=short --decorate=short --pretty=format:"shash={%h}, lhash={%H}, authname={%an}, authemail={%ae}, authsdate={%ad}, authidate={%ai}, authudate={%at}, commname={%an}, commemail={%ae}, commsdate={%ad}, commidate={%ai}, commudate={%at}, refnames={%d}, firsttagdescribe={$FIRSTTAG}, reltag={$RELTAG} " HEAD`;
        
        # When running in a sub-directories of the repo
        my $dir = ".git";
        if (!(-e $dir) and !(-d $dir)) {
            mkdir($dir);
        }

        open(my $fh,'>',$NGIN);
        print $fh "\\usepackage[".$metadata."]{gitexinfo}\n";
        close $fh;  
    }else{
        print "GIT UNCLEAN\n";   
    }

    $cmp->($GIN,$NGIN    );

    if((-e $GIN || -e $NGIN) && $cmp->($GIN, $NGIN)) {
            print "Status changed, request recompilation\n";
            $go_mode = 1;
            unlink($GIN);
            rename($NGIN, $GIN);
    } else {
        unlink($NGIN);
    }
}

git_info_2();