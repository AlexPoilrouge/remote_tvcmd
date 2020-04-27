#### About

Quick and dirty, unoptimized, and unsafe shell script wrap of [juantascon's tvcmd](https://github.com/juantascon/tvcmd) utility for deployment on a private server.


#### Server-Client version

This the main version: for a private server deployment.

Check out the `local` branch of this repository for a single user desktop version.


#### How

##### Server side

Basically, a php page executes a shell script that prints a JSON object according to the parameters that are obtain from POST requests on said php page.


##### Client side

A shell script connects and read the server's php page, obtains the JSON object as a response, which is processed and fed to a python GTK3 GUI which generates (according to user actions) new request to be send by the shell script to the server's  php page, and the loop repeats.


###### Install

To install the client side app use the script `client/install_client.sh` (`--system-install` with root privileges for system wide install)


#### Disclaimer

Made for personal use. Download, execute, install or copy at your own risks.