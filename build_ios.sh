
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

prod_mobile_provision="/usr/local/socialize/simplesample_assets/simple_sample_production.mobileprovision"
stage_mobile_provision="/usr/local/socialize/simplesample_assets/Simple_Sample_Stage_Server.mobileprovision"
provisioning_profile="iPhone Distribution: pointabout"
build_number="%env.BUILD_NUMBER%"

display_image_name="Icon.png"
full_size_image_name="Icon.png"

email="champ.somsuk@getsocialize.com"
#,Nate.Griswold@getsocialize.com,build@getsocialize.com"


function failed()
{
    local error=${1:-Undefined error}
    echo "Failed: $error" >&2
    exit 1
}

function build_ota_plist()
{
    env=$1
    cd $root_dir
    version=`cat $ios_repo/version`

    echo $artifacts_url/$target$env.ipa

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
        <string>com.getsocialize.$target$env</string>
        <key>bundle-version</key>
        <string>$version</string>
        <key>kind</key>
        <string>software</string>
        <key>subtitle</key>
        <string>$env</string>
        <key>title</key>
        <string>$project_name $env</string>
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
    rm mailbody.txt
}

function replace(){
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
}


function build_app(){
    env=$1
    cd $project_dir
     
    echo xcodebuild -target "$target$env" -sdk "$sdk"
    xcodebuild -target "$target$env"\
        #-configuration "release"
        -sdk "$sdk"\
    [ $? != 0 ] && exit 1
}

function packaging_app(){
    mobile_provision=$1
    env=$2
    
    echo /usr/bin/xcrun -sdk "$sdk" PackageApplication -v "$project_app_dir" -o "$root_dir/$target$env.ipa" --sign "$provisioning_profile" --embed "$mobile_provision" 
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
    echo "building app for PROD"
    project_app_dir="$project_dir/build/Release-iphoneos/$target.app"
    build_app
    packaging_app $prod_mobile_provision

    echo " * * * Code sign PROD * * *"
    code_sign
     
    echo " * * * change sdk config for stage * * *"
    config_host_stage

    echo " * * * build for stage * * * "
    echo "building app for STAGE"
    project_app_dir=$project_dir/build/Release-iphoneos/$target"stage".app
    echo $project_app_dir   
    build_app stage
    packaging_app $stage_mobile_provision stage

    echo " * * * Code sign * * *"
    code_sign

    echo "* * * Over The Air * * *"
    build_ota_plist    
    build_ota_plist stage

    
}
function usage(){
    echo "./build_ios.sh <NeduildType> <NedBuildId>"
}

function distribute(){
    echo " * * * SDK VERSION * * *"
    version=`cat $ios_repo/version`
    echo $version

    echo " * * * GENERATE HTML * * *"
    cp $root_dir/template.html $root_dir/index.html
    replace "%buildType%" $buildType "$root_dir/index.html"
    replace "%buildId%" $buildId "$root_dir/index.html"
    replace "%version%" $version "$root_dir/index.html"

    echo " * * * Sending E-mail * * * "
    cp $root_dir/mailtemplate.txt $root_dir/mailbody.txt
    replace "%buildType%" $buildType "$root_dir/mailbody.txt"
    replace "%buildId%" $buildId "$root_dir/mailbody.txt"  
    replace "%version%" $version "$root_dir/mailbody.txt"
    
    echo "Sending email to $email"
    mail -s "New Simple Sample Update" $email< mailbody.txt     
}


buildType=$1
buildId=$2
artifacts_url="http://ned.appmakr.com/guestAuth/repository/download/$buildType/$buildId:id"
main
[ $# == 2 ] && distribute
