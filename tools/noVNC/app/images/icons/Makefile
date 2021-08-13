ICONS := \
	nimbix-16x16.png \
	nimbix-24x24.png \
	nimbix-32x32.png \
	nimbix-48x48.png \
	nimbix-64x64.png

ANDROID_LAUNCHER := \
	nimbix-48x48.png \
	nimbix-72x72.png \
	nimbix-96x96.png \
	nimbix-144x144.png \
	nimbix-192x192.png

IPHONE_LAUNCHER := \
	nimbix-60x60.png \
	nimbix-120x120.png

IPAD_LAUNCHER := \
	nimbix-76x76.png \
	nimbix-152x152.png

ALL_ICONS := $(ICONS) $(ANDROID_LAUNCHER) $(IPHONE_LAUNCHER) $(IPAD_LAUNCHER)

all: $(ALL_ICONS)

nimbix-16x16.png: nimbix-icon-sm.svg
	convert -density 90 \
		-background transparent "$<" "$@"
nimbix-24x24.png: nimbix-icon-sm.svg
	convert -density 135 \
		-background transparent "$<" "$@"
nimbix-32x32.png: nimbix-icon-sm.svg
	convert -density 180 \
		-background transparent "$<" "$@"

nimbix-%.png: nimbix-icon.svg
	convert -density $$[`echo $* | cut -d x -f 1` * 90 / 48] \
		-background transparent "$<" "$@"

clean:
	rm -f *.png

