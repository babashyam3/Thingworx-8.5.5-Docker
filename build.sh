#!/bin/bash
source build.env

TAG_VERSION="java${JAVA_VERSION}-tomcat${TOMCAT_VERSION}"

TOMCAT_MAJOR_VERSION=${TOMCAT_VERSION%%.*}
TOMCAT_TGZ_URL=https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz

exit_status () {
    if [ $1 -ne 0 ]; then
        echo "${2}: Failed."
        exit $1
    else
        echo "${2}: Success"
    fi
}

setup_build_dir () {
    if [ ! -d "$1" ]; then
        echo "Failed to find Dockerfile dir: $1"
        exit 1
    fi
    mkdir build
    cp -r staging build/.
    cp -r "$1/." build/.
}
clean_build_dir () {
    rm -rf build
}

download_files () {
    # Apache Tomcat Signing Key
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys \
	05AB33110949707C93A279E3D3EFE6B686867BA6 \
	07E48665A34DCAFAE522E5E6266191C37C037D42 \
	47309207D818FFD8DCD3F83F1931D684307A10A5 \
	541FBE7D8F78B25E055DDEE13C370389288584E7 \
	61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
	79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
	9BA44C2621385CB966EBA586F72C284D731FABEE \
	A27677289986DB50844682F8ACB77FC2E86E29AC \
	A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
	DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
	F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
	F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23

    (
        set -e
        cd staging
        if [ ! -e "${TOMCAT_ARCHIVE}" ]; then
            echo "Downloading Tomcat: ${TOMCAT_TGZ_URL}"
            curl -fSL ${TOMCAT_TGZ_URL} -o ${TOMCAT_ARCHIVE}
            curl -fSL ${TOMCAT_TGZ_URL}.asc -o ${TOMCAT_ARCHIVE}.asc
        fi
        gpg --verify ${TOMCAT_ARCHIVE}.asc
    )
    exit_status $? "Download Tomcat"

    # mssql jdbc
    (
        cd staging
        if [ ! -e "${SQLDRIVER_FILE}" ]; then
            if [ ${SQLDRIVER_VERSION} != "6.0.8112.200" ]; then
                echo "Can't Automatically Stage version ${SQLDRIVER_VERSION} due to changing URLs. Please manually download the MSSQL JDBC jar following README instructions."
                exit 1
            fi
            echo "Downloading mssql jdbc jar"
            curl -L -C - -O https://download.microsoft.com/download/0/2/A/02AAE597-3865-456C-AE7F-613F99F850A8/sqljdbc_6.0.8112.200_enu.tar.gz
        fi
    )
    exit_status $? "Download MSSQL JDBC Jar"
}

# Build Base
build_base () {
    setup_build_dir "dockerfiles/base"
    (
        cd build
        docker build --build-arg JAVA_VERSION=${JAVA_VERSION} \
        --build-arg JAVA_ARCHIVE=${JAVA_ARCHIVE} \
        -t thingworx/base:${TAG_VERSION} \
        -t thingworx/base:latest \
        .
    )
    exit_status $? "Build Base"
    clean_build_dir
    return 0
}

# Build Platform Base
build_platform_base () {
    setup_build_dir "dockerfiles/platform/base"
    (
        cd build
        docker build --build-arg TAG_VERSION=${TAG_VERSION} \
        --build-arg TOMCAT_VERSION=${TOMCAT_VERSION} \
        --build-arg TOMCAT_ARCHIVE=${TOMCAT_ARCHIVE} \
        --build-arg LICENSE_FILE=${LICENSE_FILE} \
        --build-arg PLATFORM_SETTINGS_FILE=${PLATFORM_SETTINGS_FILE} \
        --build-arg TEMPLATE_PROCESSOR_ARCHIVE=${TEMPLATE_PROCESSOR_ARCHIVE} \
        --build-arg SECURITY_TOOL_ARCHIVE=${SECURITY_TOOL_ARCHIVE} \
        -t thingworx/tw-platform-base:${TAG_VERSION} \
        -t thingworx/tw-platform-base:latest \
        .
    )
    exit_status $? "Build Platform Base"
    clean_build_dir
    return 0
}
# Build H2
build_h2 () {
    setup_build_dir "dockerfiles/platform/h2"
    (
        cd build
        docker build --build-arg TAG_VERSION=${TAG_VERSION} \
        --build-arg PLATFORM_ARCHIVE=${PLATFORM_H2_ARCHIVE} \
        --build-arg PLATFORM_VERSION=${PLATFORM_H2_VERSION} \
        -t thingworx/platform-h2:${TAG_VERSION}-platform${PLATFORM_H2_VERSION} \
        -t thingworx/platform-h2:latest \
        .
    )
    exit_status $? "Build H2 Platform"
    clean_build_dir
    return 0
}
# Build PostgreSQL
build_postgres () {
    # Build Postgres Container
    if [ "${BUILD_TEST_DBS}" == "true" ]; then
        setup_build_dir "dockerfiles/databases/postgres"
        (
            cd build
            docker build --build-arg PLATFORM_ARCHIVE=${PLATFORM_POSTGRES_ARCHIVE} \
            --build-arg PLATFORM_VERSION=${PLATFORM_POSTGRES_VERSION} \
            -t thingworx/postgres-db:${TAG_VERSION}-platform${PLATFORM_POSTGRES_VERSION} \
            -t thingworx/postgres-db:latest \
            .
        )
        exit_status $? "Build Postgres DB"
        clean_build_dir
    fi

    # Build TWX Platform
    setup_build_dir "dockerfiles/platform/postgres"
    (
        cd build
        docker build --build-arg TAG_VERSION=${TAG_VERSION} \
        --build-arg PLATFORM_ARCHIVE=${PLATFORM_POSTGRES_ARCHIVE} \
        --build-arg PLATFORM_VERSION=${PLATFORM_POSTGRES_VERSION} \
        -t thingworx/platform-postgres:${TAG_VERSION}-platform${PLATFORM_POSTGRES_VERSION} \
        -t thingworx/platform-postgres:latest \
        .
    )
    exit_status $? "Build Postgres Platform"
    clean_build_dir
    return 0
}
# Build MSSQL
build_mssql () {
    # Build MSSQL Container
    if [ "${BUILD_TEST_DBS}" == "true" ]; then
        if [ -z "${MSSQL_DB_TWX_DATABASE_PASSWORD}" ] || [ -z "${MSSQL_DB_TWX_DATABASE_USERNAME}" ] || [ -z "${MSSQL_DB_TWX_DATABASE_SCHEMA}" ] || [ -z "${MSSQL_DB_SA_PASSWORD}" ]; then
            echo "ERROR: You must provide a User, Password, and Schema for ThingWorx and SA user password for MSSQL Test TB with the following Variables in build.env: "
            echo "MSSQL_DB_TWX_DATABASE_PASSWORD, MSSQL_DB_TWX_DATABASE_USERNAME, MSSQL_DB_TWX_DATABASE_SCHEMA, MSSQL_DB_SA_PASSWORD"
            exit 1
        fi

        setup_build_dir "dockerfiles/databases/mssql"
        (
            cd build
            docker build --build-arg PLATFORM_ARCHIVE=${PLATFORM_MSSQL_ARCHIVE} \
            --build-arg PLATFORM_VERSION=${PLATFORM_MSSQL_VERSION} \
            --build-arg TWX_DATABASE_PASSWORD=${MSSQL_DB_TWX_DATABASE_PASSWORD} \
            --build-arg TWX_DATABASE_USERNAME=${MSSQL_DB_TWX_DATABASE_USERNAME} \
            --build-arg TWX_DATABASE_SCHEMA=${MSSQL_DB_TWX_DATABASE_SCHEMA} \
            --build-arg SA_PASSWORD=${MSSQL_DB_SA_PASSWORD} \
            -t thingworx/mssql-db:${TAG_VERSION}-platform${PLATFORM_MSSQL_VERSION} \
            -t thingworx/mssql-db:latest \
            .
        )
        exit_status $? "Build MSSQL DB"
        clean_build_dir
    fi

    # Build TWX Platform
    setup_build_dir "dockerfiles/platform/mssql"
    (
        cd build
        docker build --build-arg TAG_VERSION=${TAG_VERSION} \
        --build-arg PLATFORM_ARCHIVE=${PLATFORM_MSSQL_ARCHIVE} \
        --build-arg PLATFORM_VERSION=${PLATFORM_MSSQL_VERSION} \
        --build-arg SQLDRIVER_ARCHIVE=${SQLDRIVER_ARCHIVE} \
        --build-arg SQLDRIVER_VERSION=${SQLDRIVER_VERSION} \
        -t thingworx/platform-mssql:${TAG_VERSION}-platform${PLATFORM_MSSQL_VERSION} \
        -t thingworx/platform-mssql:latest \
        .
    )
    exit_status $? "Build MSSQL Platform"
    clean_build_dir
    return 0
}

# Build Azure SQL
build_azuresql () {
    # Build TWX Platform
    setup_build_dir "dockerfiles/platform/azuresql"
    (
        cd build
        docker build --build-arg TAG_VERSION=${TAG_VERSION} \
        --build-arg PLATFORM_ARCHIVE=${PLATFORM_AZURESQL_ARCHIVE} \
        --build-arg PLATFORM_VERSION=${PLATFORM_AZURESQL_VERSION} \
        --build-arg SQLDRIVER_ARCHIVE=${AZURESQL_SQLDRIVER_ARCHIVE} \
        --build-arg SQLDRIVER_VERSION=${AZURESQL_SQLDRIVER_VERSION} \
        -t thingworx/platform-azuresql:${TAG_VERSION}-platform${PLATFORM_AZURESQL_VERSION} \
        -t thingworx/platform-azuresql:latest \
        .
    )
    exit_status $? "Build AzureSQL Platform"
    clean_build_dir
    return 0
}

# Build all variants
build_all () {
    build_base
    build_platform_base
    build_h2
    build_postgres
    build_mssql
    build_azuresql
    return 0
}

clean_build_dir

if [ $# -lt 1 ]; then
    echo "No Arguments passed."
else
    if [ "$1" == "h2" ]; then
        build_base
        build_platform_base
        build_h2
    elif [ "$1" == "postgres" ]; then
        build_base
        build_platform_base
        build_postgres
    elif [ "$1" == "mssql" ]; then
        build_base
        build_platform_base
        build_mssql
    elif [ "$1" == "azuresql" ]; then
        build_base
        build_platform_base
        build_azuresql
    elif [ "$1" == "all" ]; then
        build_all
    elif [ "$1" == "stage" ]; then
        download_files
    else
        echo "Unknown option, not building."
        exit 1
    fi
fi
