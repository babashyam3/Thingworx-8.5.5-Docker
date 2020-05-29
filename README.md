# ThingWorx Foundation Dockerfiles

## Overview
This package provides a set of Dockerfiles and supplemental scripts required to
build Docker images for ThingWorx Foundation. Dockerfiles and scripts are
provided for the following content providers:

* H2
* PostgreSQL
* Microsoft SQL Server
* Azure SQL

While there are very simple examples on how to run the images built here more in
depth examples can be found in the ThingWorx Docker Guide on the PTC Support
Downloads site alongside this release.

## Prerequisites
This topic covers the supported operating systems and required Docker software
to run ThingWorx Docker images.

### Operating System
Running the Docker images are supported on the following Operating Systems. Note
that you must use the 64-bit versions.

* Microsoft Windows 10
* Red Hat Enterprise Linux (RHEL) 7 Update 1
* Amazon EC2 Linux (64-bit)
* Ubuntu 16.04

Building the Docker images is supported only for Linux operating systems. The
scripts have been validated on Ubuntu 16.04 and should work on other Linux
operating systems that support Docker and Docker Compose. Note that PTC has
not validated other systems.

### Docker Versions
The following Docker versions are required:

* Docker Community Edition (docker-ce)

    Version 18.05.0-ce or higher is recommended. To install the Docker Community
    Edition on your system, follow the instructions for your operating system on
    the Docker web site: https://www.docker.com/community-edition#/download.

* Docker Compose (docker-compose)

    Version 1.17.1 or higher is recommended. To install the Docker Compose on
    your system, follow the instructions for your operating system on the Docker
    web site: https://docs.docker.com/compose/install/.

## Setting Up For ThingWorx Docker Builds
In order to build the ThingWorx foundation Docker images there are two major
steps that need to be done. The first is to make sure the needed binaries are
staged and available for the build process and the second is to modify the
`build.env` variable file with appropriate values.

### Required Files
In order for the variables and staging to make sense, knowing what files are
required first will help.

#### All Platform Versions
* template-processor

    This PTC provided program parses templates inside the Docker container when
    starting to inject variables and format configuration files based on the
    running environment. Example File:
    `template-processor-12.1.0.13-application.tar.gz`

* tomcat

    The Tomcat artifact obtained from Apache to run the ThingWorx Platform.
    Example File: `tomcat-9.0.21.tar.gz`

* java

    The Java JDK (version 8) obtained from Oracle. Example File: `
    jdk-8u172-linux-x64.tar.gz`

#### H2
* ThingWorx Platform H2

    Example File: `Thingworx-Platform-H2-8.5.5-b103.zip`

#### PostgreSQL
* ThingWorx Platform PostgreSQL

    Example File: `Thingworx-Platform-Postgres-8.5.5-b103.zip`

#### MSSQL
* ThingWorx Platform MSSQL

    Example File: `Thingworx-Platform-Mssql-8.5.5-b103.zip`

* MS SQL JDBC Driver

    The JDBC Driver for MS SQL obtained from Microsoft, Example File:
    `sqljdbc_6.0.8112.200_enu.tar.gz`

#### Azure SQL
* ThingWorx Platform Azure SQL

    Example File: `Thingworx-Platform-Azuresql-8.5.5-b103.zip`

* MS SQL JDBC Driver

    The JDBC Driver for MS SQL obtained from Microsoft, Example File:
    `sqljdbc_6.0.8112.200_enu.tar.gz`

### `build.env` Variables
The following are a list of variables in `build.env` that must be set.

| Variable                   | Default                                                        | Comment                                                                                                                               |
|----------------------------|----------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| JAVA_VERSION               | 8u172                                                          | The version of the Oracle Java JDK.                                                                                                   |
| TOMCAT_VERSION             | 9.0.21                                                         | The Apache Tomcat Version                                                                                                             |
| TEMPLATE_PROCESSOR_VERSION | 12.1.0.13                                     | The version of the template-processor archive as it exists in the `staging` folder.                                                   |
| PLATFORM_SETTINGS_FILE     | platform-settings.json                                         | The path to a base ThingWorx settings file. This is included in the `staging` directory.                                              |
| BUILD_TEST_DBS             | true                                                           | Set to true to build Database Images for testing, alongside the Platform Images.                                                      |
| PLATFORM_H2_VERSION        | 8.5.5-b103                                        | The version of the ThingWorx H2 Platform to build. Only required when building H2 containers.                                         |
| PLATFORM_H2_ARCHIVE        | Thingworx-Platform-H2-8.5.5-b103.zip       | The file name of the ThingWorx H2 zip as it exists in the `staging` directory. Only required when building H2 containers.             |
| PLATFORM_POSTGRES_VERSION  | 8.5.5-b103                                        | The version of the ThingWorx Postgres Platform to build. Only required when building Postgres containers.                             |
| PLATFORM_POSTGRES_ARCHIVE  | Thingworx-Platform-Postgres-8.5.5-b103.zip | The file name of the ThingWorx Postgres zip as it exists in the `staging` directory. Only required when building Postgres containers. |
| PLATFORM_MSSQL_VERSION     | 8.5.5-b103                                        | The version of the ThingWorx MSSQL Platform to build. Only required when building MSSQL containers.                                   |
| PLATFORM_MSSQL_ARCHIVE     | Thingworx-Platform-Mssql-8.5.5-b103.zip    | The file name of the ThingWorx MSSQL zip as it exists in the `staging` directory. Only required when building MSSQL containers.       |
| SQLDRIVER_VERSION          | 6.0.8112.200                                                   | The version to install of the MS SQL JDBC Driver. Only required when building MSSQL containers.                                       |
| PLATFORM_AZURESQL_VERSION     | 8.5.5-b103                                        | The version of the ThingWorx Azure SQL Platform to build. Only required when building Azure SQL containers.                                   |
| PLATFORM_AZURESQL_ARCHIVE     | Thingworx-Platform-Azuresql-8.5.5-b103.zip    | The file name of the ThingWorx Azure SQL zip as it exists in the `staging` directory. Only required when building Azure SQL containers.       |
| AZURESQL_SQLDRIVER_VERSION          | 6.0.8112.200                                                   | The version to install of the MS SQL JDBC Driver. Only required when building Azure SQL containers.                                       |
| MSSQL_DB_TWX_DATABASE_PASSWORD | No Default Value Set - Must be manually set                | If BUILD_TEST_DBS is enabled, and MSSQL images are being built this must be set to be used during the Image build process.            |
| MSSQL_DB_TWX_DATABASE_USERNAME | No Default Value Set - Must be manually set                | If BUILD_TEST_DBS is enabled, and MSSQL images are being built this must be set to be used during the Image build process.            |
| MSSQL_DB_TWX_DATABASE_SCHEMA   | No Default Value Set - Must be manually set                | If BUILD_TEST_DBS is enabled, and MSSQL images are being built this must be set to be used during the Image build process.            |
| MSSQL_DB_SA_PASSWORD           | No Default Value Set - Must be manually set                | If BUILD_TEST_DBS is enabled, and MSSQL images are being built this must be set to be used during the Image build process.            |

The following are a list of other variables in `build.env` which only need to be
modified if the default patterns do not match the files placed in the `staging`
directory.

| Variable          | Default                                 | Comment                                                                                                                         |
|-------------------|-----------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| TOMCAT_ARCHIVE    | tomcat-${TOMCAT_VERSION}.tar.gz         | The file name of the Tomcat archive as it exists in the `staging` directory.                                                    |
| JAVA_ARCHIVE      | jdk-${JAVA_VERSION}-linux-x64.tar.gz    | The file name of the Java archive as it exists in the `staging` directory.                                                      |
| SQLDRIVER_ARCHIVE | sqljdbc_${SQLDRIVER_VERSION}_enu.tar.gz | The file name of the MS SQL JDBC archive as it exists in the `staging` directory. Only required when building MSSQL containers. |
| AZURESQL_SQLDRIVER_ARCHIVE | sqljdbc_${AZURESQL_SQLDRIVER_VERSION}_enu.tar.gz | The file name of the MS SQL JDBC archive as it exists in the `staging` directory. Only required when building Azure SQL containers. |
| TEMPLATE_PROCESSOR_ARCHIVE | template-processor-${TEMPLATE_PROCESSOR_VERSION}-application.tar.gz | The file name of the template-processor archive as it exists in the `staging` folder.|
| SECURITY_TOOL_ARCHIVE | security-common-cli-${SECURITY_TOOL_VERSION}-application.tar.gz | The file name of the security tool archive as it exists in the `staging` folder.|

### Staging Files
You must put the required files for building the Docker images in the `staging`
folder that is part of this release. The `staging` folder should already contain a
base `platform-settings.json` file.

To assist with staging, Apache Tomcat and the configured version of the Microsoft
JDBC Driver for SQL Server (the default version) can be downloaded automatically.

To download automatically:
* Make sure you have set the `build.env` file variables appropriately.
* Run the command `./build.sh stage`.
If there are no errors, the files should be in the `staging` folder and they
should match your `build.env` settings.

#### Java
Java must be download manually from Oracle due to needing to accept Oracle's
Licensing terms on their site. Please visit the [Oracle JDK 8 Downloads](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)
to obtain. After accepting the License Agreement choose to download the Linux x64
tar.gz. For example: `jdk-8u181-linux-x64.tar.gz`

Save this file into the `staging` directory and make sure the `JAVA_VERSION` and
`JAVA_ARCHIVE` variables in `build.env` match.

#### ThingWorx Platform Archives
The ThingWorx Platform Archives can be downloaded from the PTC Support Downloads
site alongside this Dockerfile release. Make sure to use same ThingWorx version
as this set of Dockerfiles as there could be differences. Example File:
`Thingworx-Platform-H2-8.5.5-b103.zip`

Save this file into the `staging` directory and make sure the `PLATFORM_*_VERSION`
and `PLATFORM_*_ARCHIVE` variables match the file.

#### Template Processor Archive
The template-processor program is included in the `staging` directory and should
be included in the Docker builds automatically. Double check the version and
archive file name in `staging` match your `build.env` settings.

#### Security Tool Archive
The security-tool program is included in the `staging` directory and should
be included in the Docker builds automatically. Double check the version and
archive file name in `staging` match your `build.env` settings.

#### Tomcat Archive
If the attempt to automatically download Tomcat does not work it can be downloaded
directly from Apache at the following link: [Tomcat 8 Downloads](https://tomcat.apache.org/download-80.cgi)
Choose to download the `Core` version and get the `tar.gz`. Example File: `apache-tomcat-8.5.33.tar.gz`

Save this file into the `staging` directory and make sure the `TOMCAT_VERSION`
and `TOMCAT_ARCHIVE` variables in `build.end` match.

#### MS SQL JDBC Driver
If the attempt to automatically download the MS SQL JDBC Driver doesn't work, or
an alternate version is desired it can be obtained from [Microsoft JDBC Driver 6.0](https://www.microsoft.com/en-us/download/details.aspx?id=11774)
Choose to download the English version (as the file structure differs with
alternate languages). One the following screen, select `sqljdbc_<version>_enu.tar.gz`
and click Next.

Save this file into the `staging` directory and make sure the `SQLDRIVER_VERSION`,
`SQLDRIVER_ARCHIVE`, `AZURESQL_SQLDRIVER_VERSION`, and `AZURESQL_SQLDRIVER_ARCHIVE`
variables in `build.env` match as needed.

## Building The ThingWorx Foundation Images
With the setup complete, it is now possible to run the build script to create the
Docker images.

The included `build.sh` script is able to take the variables set previously and
work with the `staging` directory to make sure the Docker build command has the
appropriate variables and build context passed in.

To build the images run the command: `./build.sh <type>`
`type` can be any one of the following: `h2`, `postgres`, `mssql`, or `azuresql`.

After the build process completes there will be Docker images available depending
on the content provider you built.

* H2

    Platform Docker Image: `thingworx/platform-h2:latest`

* PostgreSQL

    Platform Docker Image: `thingworx/platform-postgres:latest`
    PostgreSQL DB Docker Image: `thingworx/postgres-db:latest`

* MSSQL

    Platform Docker Image: `thingworx/platform-mssql:latest`
    MS SQL DB Docker Image: `thingworx/mssql-db:latest`

* Azure SQL

    Platform Docker Image: `thingworx/platform-azuresql:latest`

**NOTE** The DB Docker Images for PostgreSQL and MSSQL aren't intended for
production use. They are for testing and development.

## Using and Running the ThingWorx Docker Images
Included in this release are some basic Docker Compose files intended to help
test the build ThingWorx Images.

To start the compose environment, you can run `docker-compose -f docker-compose-<type>.yml up -d`
`type` can be any one of the following: `h2`, `postgres`, `mssql`, or `azuresql`.

For example, to start, view the logs, and stop the H2 image:
```
docker-compose -f docker-compose-h2.yml up -d
docker-compose -f docker-compose-h2.yml logs -f
<ctrl-c>
docker-compose -f docker-compose-h2.yml down
```

This guide is mainly targeting the building of the Docker Images. For more detailed
usage examples and configuration please see the full documentation that can be
found in the ThingWorx Docker Guide on the PTC Support Downloads site alongside
this release.
