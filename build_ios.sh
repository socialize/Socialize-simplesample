
##  App config
old_redirect_host="http://r.getsocialize.com"
redirect_host="http://stage.getsocialize.com"
old_https_host="https://api.getsocialize.com"
https_host="https://stage.api.getsocialize.com"
old_http_host="http://api.getsocialize.com"
http_host="http://stage.api.getsocialize.com"
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
config_path="build/Socialize.embeddedframework/Socialize.framework/Versions/A/Resources/"
config_file="SocializeConfigurationInfo.plist"
environment="stage"
target="simplesample"
sdk="iphoneos5.1"

project_app_dir="$project_dir/build/Release-iphoneos/$target.app"
mobile_provision="/usr/local/socialize/simple_sample_production.mobileprovision"
provisioning_profile="iPhone Distribution: pointabout"
build_number="%env.BUILD_NUMBER%"

display_image_name="Icon.png"
full_size_image_name="Icon.png"

function failed()
{
    local error=${1:-Undefined error}
    echo "Failed: $error" >&2
    exit 1
}

function build_ota_plist()
{
    env=$1
    artifacts_url="http://ned.appmakr.com/repository/download/$buildType/$buildId:id"
    cd $root_dir
    version=`cat $ios_repo/version`
    echo "Generating $target$env.plist"
    cat << EOF > $root_dir/$target$env.plist
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
          <string>$artifacts_url/$target$env.ipa</string>
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
        <string>com.getsocialize.simplesample</string>
        <key>bundle-version</key>
        <string>$version</string>
        <key>kind</key>
        <string>software</string>
        <key>subtitle</key>
        <string>$env</string>
        <key>title</key>
        <string>$project_name</string>
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
    rm -rfv simplesample*
    echo ">>> remove htmlpage"
    rm index.html
}

function replace(){
    echo $0 $1 $2 $3
    mv $3 $3_old
    sed -e "s@$1@$2@g" $3_old  > $3
    rm -f $3_old
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
function config_host_stage(){
    cd $root_dir/$ios_repo/$config_path
    echo "begin replace config on socialize config"
    replace $old_redirect_host $redirect_host $config_file
    replace $old_https_host $https_host $config_file
    replace $old_http_host $http_host $config_file
    #sed -e "s@$old_redirect_host@$redirect_host@g" $config_file  > $config_file
    #sed -e "s@$old_https_host@$https_host@g" $config_file > $config_file
    #sed -e "s@$old_http_host@$http_host@g" $config_file > $config_file
}


function build_app(){
    cd $project_dir
    xcodebuild -target "$target"\
        -sdk "$sdk"\
        -configuration release
    [ $? != 0 ] && exit 1
}

function packaging_app(){
    env=$1
    /usr/bin/xcrun -sdk "$sdk" PackageApplication -v "$project_app_dir" -o "$root_dir/$target$env.ipa" --sign "$provisioning_profile" --embed "$mobile_provision"
    [ $? != 0 ] && exit 1
}

function code_sign(){
    codesign -d -vvv --file-list - "$project_app_dir"
    [ $? != 0 ] && exit 1
}


function main(){

    echo " * * * clean * * * "
    clean   

    echo " * * * git clone & build * * *"
    git_build

    echo " * * * build for prod * * * "
    build_app
    packaging_app prod
    
    echo " * * * change sdk config for stage * * *"
    config_host_stage

    echo " * * * build for stage * * * "
    build_app
    packaging_app stage

    echo " * * * Code sign * * *"
    code_sign

    echo "* * * Over The Air * * *"
    build_ota_plist stage
    build_ota_plist prod      

    echo " * * * SDK VERSION * * *"
    cd $root_dir
    cat $ios_repo/version

    echo " * * * GENERATE HTML * * *"
    cp $root_dir/template.html $root_dir/index.html
    replace "%buildType%" $buildType "$root_dir/index.html"
    replace "%buildId%" $buildId "$root_dir/index.html"
}
function usage(){
    echo "./build_ios.sh <NeduildType> <NedBuildId>"
}
[ $# -lt 2 ] && usage && exit 1                     
buildType=$1
buildId=$2  
main 
