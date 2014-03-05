# get the mime type for a file
function get_mime_type {
  file -L --mime-type $argv[1] | cut -d: -f2 | cut -c 2-
}

function get_file_extension {
  echo ${argv[1]##*.}
}

# quickly open a file with the appropriate application
function o {
  [[ $argv[1] == "-e" || $argv[1] == "--edit" ]] && {
    edit_mode=true
    shift
  } || edit_mode=false

  for f in $argv;
  do
    mime_type=$(get_mime_type $f)
    case $mime_type in
      (application/pdf)
        application=acroread
        ;;
      (image/png)
        #application=feh
        application=chromium
        $edit_mode && application=inkscape
        ;;
      (application/octet-stream)
        # generic bytestream. let's try to use the extension.
        extension=$(get_file_extension $f)
        case $extension in 
          (idb)
            application=idaq
            ;;
          (*)
            print "Unknown file type $mime_type and extension $extension"
        esac

        ;;
      (*) print "Unknown file type $mime_type"
        application=
        ;;
    esac
    [[ ! -z $application ]] && stfu $application $f
  done
  
}
