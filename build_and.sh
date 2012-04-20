
##  App config
old_redirect_host="http://r.getsocialize.com"
redirect_host="http://stage.getsocialize.com"
old_https_host="https://api.getsocialize.com"
https_host="https://stage.api.getsocialize.com"
old_http_host="http://api.getsocialize.com"
http_host="http://stage.api.getsocialize.com"
consumer_key="8d4afa04-0ab8-4173-891a-5027c8b827f6"
consumer_secret="25957111-3f42-413d-8d5b-a602c32680d5"
stage_consumer_key="bc152bdf-1497-447a-9e6b-758d4856758f"
stage_consumer_secret="79c544ca-fbe1-4da4-8bf4-0decedc24e65"
android_build_folder="android_build"


facebook_app_id="193049117470843"
stage_facebook_app_id="210343369066525"
and_repo="socialize-sdk-android"
and_git_clone="git clone -b develop git@github.com:socialize/socialize-sdk-android.git $and_repo"

## Android APK config
project_name="simple-sample"
root_dir=`pwd`
project_dir=$root_dir/$and_repo/$project_name
assets_dir=$project_dir/assets
stage_build_dir=$root_dir/$android_build_folder/build_stage
prod_build_dir=$root_dir/$android_build_folder/build_prod

display_image_name="Icon.png"
full_size_image_name="Icon.png"

#email="champ.somsuk@getsocialize.com,Nate.Griswold@getsocialize.com,builds@getsocialize.com"


function failed()
{
    local error=${1:-Undefined error}
    echo "Failed: $error" >&2
    exit 1
}

function replace()
{
    mv $3 $3_old
    sed -e "s&$1&$2&g" $3_old  > $3
    rm -f $3_old
}    

function clean(){
    cd $root_dir
    echo ">>> remove stage build folder"
    rm -rfv $stage_build_dir
    echo ">>> remove prod build folder"
    rm -rfv $prod_build_dir
    echo ">>> remove public path on NED"
    rm -v /opt/TeamCity/webapps/ROOT/socialize_builds/*
}

function git_build_android(){

    cd $root_dir
    if [ -d $and_repo ]; then
        cd $and_repo && git reset --hard HEAD && git pull && git submodule update
    else
        $and_git_clone && cd $and_repo && git submodule update --init
    fi
}

function build_app(){
    build_env=$1
    cd $project_dir    
    if [ "$build_env" == "prod" ]; then
        config_local_properties $prod_build_dir 
        config_socialize_properties $consumer_key $consumer_secret $facebook_app_id "api"
    else
        config_local_properties $stage_build_dir 
        config_socialize_properties $stage_consumer_key $stage_consumer_secret $stage_facebook_app_id "stage.api"
    fi    

    echo " * * * RUNNING ANT SCRIPT * * * "    
    cd $project_dir
    ant release
    [ $? == 1 ] && exit 1
    

}

function config_local_properties(){
    cd $project_dir   
    build_target=$1
    echo "remove local.properties"
    rm -rvf local.properties
    echo "set up local.properties $build_target"
    cat <<EOF >local.properties
sdk.dir=$ANDROID_HOME
out.dir=$build_target
EOF
}


function config_socialize_properties(){
    config_consumer_key=$1
    config_consumer_secret=$2
    config_facebook_app_id=$3 
    env=$4

    echo $config_consumer_key $config_consumer_secret $config_facebook_app_id $env

    echo "remove socialize.properties"
    rm -rvf $assets_dir/socialize.properties
    cd $assets_dir
   
    cat <<EOF >socialize.properties
socialize.consumer.key=$config_consumer_key
socialize.consumer.secret=$config_consumer_secret
facebook.app.id=$config_facebook_app_id
twitter.consumer.key=PlOb10oxhUAy2CFuUo5Ew
twitter.consumer.secret=lBJQuDVCvK769tmMpzC3kSdr2gcOu0Q18ywPtTt2dk
log.level=DEBUG
socialize.entity.loader=com.socialize.sample.simple.SampleEntityLoader
socialize.allow.anon=true
api.host=http://$env.getsocialize.com/v1
EOF
}

function config_stage(){
    echo "go to android manifest"
    cd $project_dir
    menifest_file=AndroidManifest.xml
    replace '"com.socialize.sample.simple"' '"com.socialize.sample.simple.stage"' $menifest_file
    replace @string/app_name StageSimpleSample $menifest_file
}

function main(){
    echo " * * * clean * * * "
    clean

    echo " * * * git clone & build * * *"
    git_build_android   
    
    echo " * * * build for prod * * * "
    build_app prod

    echo " * * * config stage parameters * * *"
    config_stage

    echo " * * * build for stage * * * "
    build_app stage

    prepare_apk
    exit 0

}
function usage(){
    echo "./build_and.sh"
}

function prepare_apk(){
    build_path=/opt/TeamCity/webapps/ROOT/socialize_builds
    cd $project_dir/libs 
    echo `find -f socialize-*jar` > $build_path/android_version
    mv $stage_build_dir/socialize-simple-sample-release.apk $build_path/socialize-simple-sample-release-stage.apk
    mv $prod_build_dir/socialize-simple-sample-release.apk $build_path/socialize-simple-sample-release-prod.apk
    exit 0
}




buildType=$1
buildId=$2
artifacts_url="http://ned.appmakr.com/guestAuth/repository/download/$buildType/$buildId:id"
main
[ $# == 2 ] && distribute
