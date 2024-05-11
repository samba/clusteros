#!/usr/bin/env awk
# Rewrite the grub configuration to set nicer default behavior for fully automated installation


BEGIN {
    idcounter=0
    first=1 # logically necessary -- the first match below
}


{

    if ( $0 ~ /^set theme/ ) {
        printf("%s\nset default=automated-%d\n", $0, first);
        next;
    }

    if ( $0 ~ /Automated install/ )  {
        idcounter++
        gsub(/{/, sprintf("id=automated-%d {", idcounter));
    }


    print;
}


END {

}
