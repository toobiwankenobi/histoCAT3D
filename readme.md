# histoCAT++

Software developed by Raúl Catena in the Bodenmiller laboratory to perform IMC analysis, computer vision on IMC images, cell segmentation, mask learning, cell data dimensionality reduction, clustering, plotting, classification with standard machine learning, registration, multimodal image stitching, 3D reconstruction, exporting to different formats, and 3D data analysis.

> **About this fork**
> This is a fork of [BodenmillerGroup/histoCAT3D](https://github.com/BodenmillerGroup/histoCAT3D) that builds natively on Apple Silicon Macs and fixes several bugs. Only the **histoCAT Viewer** app is released from this fork. For histoCAT++ and histoCAT++3D binaries, and for Intel Macs, use the [original release](https://github.com/BodenmillerGroup/histoCAT3D/releases).

## Changes in this fork

- **Polygon ROIs:** fixed display of polygon-shaped acquisitions from MCD files ([#4](https://github.com/BodenmillerGroup/histoCAT3D/issues/4))
- **Crash fix:** fixed a crash when opening files (file checksum loop started at a null pointer)
- **Apple Silicon:** native arm64 build with current Xcode and macOS
- **Numeric input:** input fields next to the Max, Offset and Mult sliders to enter values directly (Max and Offset in counts)
- **Performance:** MCD files are memory-mapped instead of loaded completely into RAM; faster parsing of MCD metadata
- **Display:** fixed oversized color bars without min/max labels, and similar layout issues in histograms and plots, on recent macOS versions

## Using the histoCAT Viewer release

Download `histoCAT Viewer.app.zip` from the [Releases](../../releases) page, unzip it and move the app to your Applications folder.

- **Requirements:** Mac with Apple Silicon (M1 or newer). Intel Macs are not supported by this build.
- **No dependencies:** the app is standalone and contains copies of all required libraries.
- **First launch:** the app is not notarized by Apple. Open it with right-click → **Open**, or run:

      xattr -dr com.apple.quarantine "/Applications/histoCAT Viewer.app"

## Building from source

### Dependencies

Install [Xcode](https://developer.apple.com/xcode/) and the libraries with [Homebrew](https://brew.sh):

    brew install opencv@4 libtiff

The project links OpenCV 4 from `/opt/homebrew/opt/opencv@4` and libtiff from `/opt/homebrew/opt/libtiff`. OpenCV 5 (Homebrew's default `opencv` formula) is not supported, because it moved the `ml` module used by histoCAT++ to opencv_contrib.

### Building

1. Open `3DIMC.xcodeproj` in Xcode.
2. Select the scheme **histoCAT Viewer** (or histoCAT++ / histoCAT++3D) and press ⌘R.

Builds run on Apple Silicon only (`ARCHS = arm64`), since the Homebrew libraries are arm64-only. Apps built this way load the libraries from Homebrew and only run on Macs with the same Homebrew packages installed.

### Creating a standalone app

1. **Product → Archive**, then in the Organizer **Distribute App → Custom → Copy App**.
2. Copy the libraries into the app with [dylibbundler](https://github.com/auriamg/macdylibbundler):

       brew install dylibbundler
       APP="histoCAT Viewer.app"
       dylibbundler -od -b -x "$APP/Contents/MacOS/histoCAT Viewer" \
         -d "$APP/Contents/Frameworks" -p @executable_path/../Frameworks/
       codesign --force --deep --sign - "$APP"

3. Check that no library is loaded from Homebrew any more (this should print nothing):

       otool -L "$APP/Contents/MacOS/histoCAT Viewer" | grep homebrew

4. Zip it for distribution:

       ditto -c -k --keepParent "$APP" "$APP.zip"

**Notes:**
- Use Apple's `install_name_tool` and `otool`. Conda/Anaconda ships its own versions (cctools-port) that corrupt the bundled libraries. Run `conda deactivate` first, and check with `which install_name_tool` that it points to `/usr/bin`.
- macOS refuses to start apps with duplicate `LC_RPATH` entries. If the app crashes with "duplicate LC_RPATH", remove the duplicate with `install_name_tool -delete_rpath` in the file named in the crash report.
- Hardened Runtime is disabled for the targets, as its library validation blocks ad-hoc signed libraries.

## R (optional, for plotting)

The plotting features of histoCAT++ and histoCAT++3D use R; R is not needed to view images. Install R (arm64 build for Apple Silicon) from [CRAN](https://cran.r-project.org) in the standard location `/Library/Frameworks/R.framework`, open the R console and run:

    install.packages("ggplot2"); install.packages("RColorBrewer")

A different R location can be set in the app's Preferences.

## License

AGPL-3.0, see [License-AGPL3.0.txt](License-AGPL3.0.txt).

## References

Raúl Catena et al. Journal of Pathology, February 2018.
