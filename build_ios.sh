
##  App config
api_host="http://stage.api.getsocialize.com"
consumer_key="8d4afa04-0ab8-4173-891a-5027c8b827f6"
consumer_secret="25957111-3f42-413d-8d5b-a602c32680d5"
facebook_app_id="193049117470843"

ios_repo="socialize-sdk-ios"
git_clone="git clone git@github.com:socialize/socialize-sdk-ios.git $ios_repo"

## Xcode config
project_name="BurgerTime"
root_dir=`pwd`
project_dir=$root_dir/$project_name
build_dir=$project_dir/build
environment="stage"
target="simplesample"
sdk="iphoneos5.1"

project_app_dir="$project_dir/build/Release-iphoneos/$target.app"
mobile_provision="/usr/local/socialize/simple_sample_production.mobileprovision"
provisioning_profile="iPhone Distribution: pointabout"
build_number="%env.BUILD_NUMBER%"
artifacts_url="http://ned.appmakr.com/artifacts/$build_number"
display_image_name="Icon-57.png"
full_size_image_name="Icon-512.png"

function failed()
{
    local error=${1:-Undefined error}
    echo "Failed: $error" >&2
    exit 1
}

function build_ota_plist()
{
  echo "Generating $target.app.plist"
  cat << EOF > $root_dir/$target.app.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>items</key>
  <array>
    <dict>
      <key>assets</key>
      <array>
        <dict>
          <key>kind</key>
          <string>software-package</string>
          <key>url</key>
          <string>$artifacts_url/$target.ipa</string>
        </dict>
        <dict>
          <key>kind</key>
          <string>full-size-image</string>
          <key>needs-shine</key>
          <true/>
          <key>url</key>
          <string>$artifacts_url/$full_size_image_name</string>
        </dict>
        <dict>
          <key>kind</key>
          <string>display-image</string>
          <key>needs-shine</key>
          <true/>
          <key>url</key>
          <string>$artifacts_url/$display_image_name</string>
        </dict>
      </array>
      <key>metadata</key>
      <dict>
        <key>bundle-identifier</key>
        <string>001</string>
        <key>bundle-version</key>
        <string>test 001</string>
        <key>kind</key>
        <string>software</string>
        <key>subtitle</key>
        <string>stage</string>
        <key>title</key>
        <string>$BurgerTime</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>
EOF
}

function clean(){
    cd $root_dir
    echo ">>> remove all file in $build_dir/*"
    rm -rf $build_dir/*
    echo ">>> remove simplesample.ipa"
    rm simplesample.ipa
}

function git_build(){
    cd $root_dir
    if [ -d $ios_repo ]; then
        cd $ios_repo && git pull && git submodule update
    else
        $git_clone && cd $ios_repo && git submodule update --init
    fi
    make package

}
function build_app(){
    cd $project_dir
    xcodebuild -target "$target"\
        -sdk "$sdk"\
        -configuration release
    [ $? != 0 ] && exit 1
}

function packaging_app(){
    /usr/bin/xcrun -sdk "$sdk" PackageApplication -v "$project_app_dir" -o "$root_dir/$target.ipa" --sign "$provisioning_profile" --embed "$mobile_provision"
    [ $? != 0 ] && exit 1
}

function code_sign(){
    codesign -d -vvv --file-list - "$project_app_dir"
    [ $? != 0 ] && exit 1
}


function main(){
    

    echo " * * * clean * * * "
    #clean   

    echo " * * * git clone & build * * *"
    #git_build

    echo " * * * build * * * "
    #build_app

    echo " * * * Packaging * * * "
    packaging_app

    echo " * * * Code sign * * *"
    code_sign

    echo "* * * Over The Air * * *"
    build_ota_plist                  
}

main
