{pkgs, ...}: {
  # CD ripping toolchain: abcde + encoders + helpers.
  # Album art via glyrc, MusicBrainz tagging via cd-discid + libdiscid.
  home.packages = with pkgs; [
    abcde
    cdparanoia-iii
    flac
    lame
    vorbis-tools
    id3v2 # MP3 tagger (replaces flaky eyeD3)
    eject
    glyr # cover art fetcher used by the post-encode hook below
  ];

  home.file.".abcde.conf".text = ''
    # ~/.abcde.conf — declarative config managed by home-manager

    # --- Drive ---
    CDROM=/dev/sr0
    CDROMREADERSYNTAX=cdparanoia
    CDPARANOIA=cdparanoia
    CDPARANOIAOPTS="--never-skip=40"

    # --- Metadata ---
    CDDBMETHOD=musicbrainz
    MUSICBRAINZSERVER=musicbrainz.org

    # --- Encoding ---
    # Default to FLAC. Override per-run with: abcde -o flac,mp3
    OUTPUTTYPE=flac
    FLACENCODERSYNTAX=flac
    FLAC=flac
    FLACOPTS="--best --verify"

    LAMEENCODERSYNTAX=lame
    LAME=lame
    LAMEOPTS="-V 0 --vbr-new --add-id3v2"

    # eyeD3 fails on genre code 255 (unknown). Use id3v2 instead.
    MP3TAGGER=id3v2
    ID3V2=id3v2

    # --- Output layout: ~/Music/Artist/Album/01 - Track.flac ---
    OUTPUTDIR="$HOME/Music"
    # Escape $ so bash leaves vars alone at source time; abcde substitutes later.
    OUTPUTFORMAT="\''${ARTISTFILE}/\''${ALBUMFILE}/\''${TRACKNUM} - \''${TRACKFILE}"
    VAOUTPUTFORMAT="Various/\''${ALBUMFILE}/\''${TRACKNUM} - \''${ARTISTFILE} - \''${TRACKFILE}"
    ONETRACKOUTPUTFORMAT="\''${ARTISTFILE}/\''${ALBUMFILE}/\''${ALBUMFILE}"
    VAONETRACKOUTPUTFORMAT="Various/\''${ALBUMFILE}/\''${ALBUMFILE}"
    PADTRACKS=y
    MAXPROCS=4

    # Spaces are friendlier than underscores for browsing.
    mungefilename ()
    {
      echo "$@" | sed 's/[\\\/\:\*\?\"\<\>\|]/-/g'
    }

    # --- Behavior ---
    EJECTCD=y
    KEEPWAVS=n
    BATCHNORM=n
    NOGAP=n
    PLAYLISTFORMAT="\''${ARTISTFILE}/\''${ALBUMFILE}/\''${ALBUMFILE}.m3u"

    # --- Album art via glyrc ---
    POST_ENCODE=do_getalbumart
    do_getalbumart ()
    {
      cover_dir="$OUTPUTDIR/$(mungefilename "$TRACKARTIST")/$(mungefilename "$DALBUM")"
      mkdir -p "$cover_dir"
      ${pkgs.glyr}/bin/glyrc cover \
        --artist "$TRACKARTIST" \
        --album "$DALBUM" \
        --write "$cover_dir/cover.jpg" \
        --from 'all' >/dev/null 2>&1 || true
    }
  '';
}
