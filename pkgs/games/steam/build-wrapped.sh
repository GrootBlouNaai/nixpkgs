# Source the standard environment setup script
# This script initializes the build environment, setting up variables and paths required for the build process.
source $stdenv/setup

# Define the output directory for the Steam runtime
# This directory will contain the runtime environment that Steam will use.
outp=$out/lib/steam-runtime

# Function to build the runtime directory structure
# This function processes a list of paths and packages, copying or linking the necessary files into the runtime directory.
buildDir() {
  paths="$1"  # List of paths to process (e.g., lib, bin)
  pkgs="$2"   # List of packages to process

  # Iterate over each package
  for pkg in $pkgs; do
    echo "adding package $pkg"

    # Iterate over each path within the package
    for path in $paths; do
      if [ -d $pkg/$path ]; then
        cd $pkg/$path

        # Iterate over each file in the current path
        for file in *; do
          found=""

          # Check if the file already exists in the output paths
          for i in $paths; do
            if [ -e "$outp/$i/$file" ]; then
              found=1
              break
            fi
          done

          # If the file does not exist in the output paths, link it
          if [ -z "$found" ]; then
            mkdir -p $outp/$path
            ln -s "$pkg/$path/$file" $outp/$path

            # Handle versioned shared object files (e.g., .so.1.2.3)
            sovers=$(echo $file | perl -ne 'print if s/.*?\.so\.(.*)/\1/')
            if [ ! -z "$sovers" ]; then
              fname=''${file%.''${sovers}}
              for ver in ''${sovers//./ }; do
                found=""
                for i in $paths; do
                  if [ -e "$outp/$i/$fname" ]; then
                    found=1
                    break
                  fi
                done
                [ -n "$found" ] || ln -s "$pkg/$path/$file" "$outp/$path/$fname"
                fname="$fname.$ver"
              done
            fi
          fi
        done
      fi
    done
  done
}

# Evaluate the install phase commands
# This command executes the install phase, which typically includes building and installing the runtime environment.
eval "$installPhase"
