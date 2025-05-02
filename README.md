# RazWall Aplha 1.3 ISO Release 4/8/2025

I have added a new and experimental interface. This is far from complete, but It gives a us a fresh canvas to use Instead of fighting with the old 3ndian stuff slopped on top to pfsense and ipcop code.

Bug fix:
Fixed permissions +x for razi3 causing error on console 

Default Console UI Login:

User: `admin`

Password: `razwall`

# RazWall Aplha 1.2 ISO Release 3/28/2025

This ISO release includes the first RazWall Package. This is FAR from stable or usable but its a great test bed for anyone anxious to start working with this project since it contains everything I have worked on so far.

Default Console UI Login:

User: `admin`

Password: `razwall`


*A quick note: I have found a hug bug right after install.. The console does not not start.
To fix this:

CTL+ALT+F2 to get console 2

Login as root with the password you set during install.

run command: `chmod +x /razwall/razi3`

run command: `reboot`

After reboot, you should reach the UI Login on console 1

# RazWall Alpha 1.1 ISO Release

This ISO release consolidates all required packages to the R package group to force users to install all required packages for RazWall.

This ISO will not install RazWall (yet) it is just a test, but this is probably close to the final ISO. I will publish all of the build data to github.

[Project GitHub](https://github.com/p3rlphr33k/razwall)

# RazWall Alpha 1.0 ISO Release

This ISO release contains a test 'R' for packages and a repacked initrd.img with modified scripts.

This ISO will not install RazWall (yet) it is just a test.

# RazWall pre-Alpha ISO release

This ISO pre-Alpha release is a test for the upcoming RazWall firewall installer.

Whats in the ISO:
Slackware64 15 DVD with limited package groups: A,AP,D,L,N and a staged R

This ISO will not install RazWall (yet) it is just a test.

For a full description of this project, visit the
[project website](https://razwall.com/).

Submit bug reports and feature suggestions, or track changes in the
[support forum](https://razwall.com/forum/).
