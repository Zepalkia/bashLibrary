# bashLibrary

This project is a collection of bash scripts offering lots of useful functionalities and examples about how to implement specific behaviour using bash.

## Main features
1. UI creation with text window, dynamic prompt, keyboard and mouse interactions, waiting bars and more
2. Global/Scope locking features to have thread-safety between functions/scripts/process
3. Thread-like create/join/kill features to create easily background process
4. Creation of automated unit-test to check functions of any bash script
5. WiFi handling with hotspot creation, connection sharing and more
6. Lots of small handy features than can help a lot creating bash scripts with already-made frequent functionalities
7. Validated using shellcheck + unit-tests using the testing capabilities of the library

## Ongoing feature development
- [ ] Feature 1

## Library generation

You can directly download the latest 'bashLibrary.sh' script from the release list

>

You can as well clone the full repository and run in the root folder the 'generateLibrary.sh' script manually

> bash generateLibrary.sh

## Disclaimer
- The package inotify-tools is required for some features (threads, some locking function, waitbar)
- The packages git, network-manager, isc-dhcp-server and iptables are required for related features (git, wifi&networking)
- A lot of features require the presence of a writable /tmp partition
- This whole project isn't POSIX-complient and some features are bash-only and are not compatible with other shells
- Shell programming is a huge world with often multiple solutions to a single problem, the solutions implemented in this library may not be the best one
