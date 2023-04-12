#!/bin/bash
set -e
# Set variables for Revanced
readonly revanced_name="revanced"
readonly revanced_user="revanced"
# Set variables for Revanced Extended
readonly revanced_extended_name="revanced-extended"
readonly revanced_extended_user="inotia00"
# Function download latest github releases 
download_latest_release() {
    echo "⏬ Downloading $name resources..."
    for repos in revanced-patches revanced-cli revanced-integrations; do
       local url="https://api.github.com/repos/$user/$repos/releases/latest"
       curl -s "$url" | jq -r '.assets[].browser_download_url' | xargs -n 1 curl -O -s -L
   done
}
# Function download YouTube apk from APKmirror
req() {
    curl -sSL -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:111.0) Gecko/20100101 Firefox/111.0" "$1" -o "$2"
}
dl_ytms() {
    rm -rf $2
    echo "⏬ Downloading YouTube Music $1"
    url="https://www.apkmirror.com/apk/google-inc/youtube/youtube-music-${1//./-}-release/"
    url="$url$(req "$url" - | grep arm64 -A30 | grep youtube-music | head -1 | sed "s#.*-release/##g;s#/\".*##g")"
    url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
    url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
    req "$url" "$2"
}
get_latest_ytmsversion() {
    url="https://www.apkmirror.com/apk/google-inc/youtube-music/"
    ytmsversion=$(req "$url" - | grep "All version" -A200 | grep app_release | sed 's:.*/youtube-music-::g;s:-release/.*::g;s:-:.:g' | sort -r | head -1)
    echo "🔸 Latest Youtube Music Version: $ytmsversion"
}
get_support_ytmsversion() {
    ytmsversion=$(jq -r '.[] | select(.name == "hide-get-premium") | .compatiblePackages[] | select(.name == "com.google.android.apps.youtube.music") | .versions[-1]' patches.json)
}
# Function Patch APK
patch_msrv() {
echo "⚙️ Patching YouTube Music..."
java -jar revanced-cli*.jar \
     -m revanced-integrations*.apk \
     -b revanced-patches*.jar \
     -a youtube-music-v$ytmsversion.apk \
     --keystore=ks.keystore \
     -o ytms-$name-v$ytmsversion.apk
}
patch_msrve() {
echo "⚙️ Patching YouTube Music..."
java -jar revanced-cli*.jar \
     -m revanced-integrations*.apk \
     -b revanced-patches*.jar \
     -a youtube-music-v$ytmsversion.apk \
     -e custom-branding-music-afn-red \
     --keystore=ks.keystore \
     -o ytms-$name-v$ytmsversion.apk
}
# Function clean caches to new build
clean_cache() {
echo "🧹 Clean caches..."
rm -f revanced-cli*.jar \
      revanced-integrations*.apk \
      revanced-patches*.jar \
      patches.json \
      options.toml \
      youtube-music*.apk \ 
}
# Loop over Revanced & Revanced Extended 
for name in $revanced_name $revanced_extended_name ; do
    # Select variables based on name
    if [[ "$name" = "$revanced_name" ]]; then
        user="$revanced_user"
        patch_file="$revanced_patch"
    else
        user="$revanced_extended_user"
        patch_file="$revanced_extended_patch"
    fi  
download_latest_release
    if [[ "$name" = "$revanced_name" ]] ; then
        get_support_ytmsversion
        dl_ytms $ytmsversion youtube-music-v$ytmsversion.apk 
        patch_msrv
     else 
        get_latest_ytmsversion 
        dl_ytms $ytmsversion youtube-music-v$ytmsversion.apk 
        patch_msrve
     fi
clean_cache
done
