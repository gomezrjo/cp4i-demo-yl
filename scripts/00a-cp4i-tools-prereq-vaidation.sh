#!/bin/bash
# BOLD COLORS
BLACK_BOLD='\033[1;30m'
RED_BOLD='\033[1;31m'
GREEN_BOLD='\033[1;32m'
YELLOW_BOLD='\033[1;33m'
BLUE_BOLD='\033[1;34m'
MAGENTA_BOLD='\033[1;35m'
CYAN_BOLD='\033[1;36m'
WHITE_BOLD='\033[1;37m'
RESET='\033[0m'
if [ ! command -v oc &> /dev/null ]; then echo -e "${RED_BOLD}oc could not be found${RESET}"; exit 1; fi;
if [ ! command -v zip &> /dev/null ]; then echo -e "${RED_BOLD}zip could not be found${RESET}"; exit 1; fi;
if [ ! command -v keytool &> /dev/null ]; then echo -e "${RED_BOLD}keytool could not be found${RESET}"; exit 1; fi;
if [ ! command -v openssl &> /dev/null ]; then echo -e "${RED_BOLD}openssl could not be found${RESET}"; exit 1; fi;
if [ ! command -v jq &> /dev/null ]; then echo -e "${RED_BOLD}jq could not be found${RESET}"; exit 1; fi;
if [ ! command -v yq &> /dev/null ]; then echo -e "${RED_BOLD}yq could not be found${RESET}"; exit 1; fi;
if [ ! command -v awk &> /dev/null ]; then echo -e "${RED_BOLD}awk could not be found${RESET}"; exit 1; fi;
if [ ! command -v apic &> /dev/null ]; then echo -e "${RED_BOLD}apic could not be found${RESET}"; exit 1; fi;
echo -e "${YELLOW_BOLD}The minimum Tools required by this repo are available in your workstation. You can proceed.${RESET}"
if [ ! command -v podman &> /dev/null ]; then echo -e "${RED_BOLD}podman could not be found${RESET}"; exit 1; fi;
if [ ! command -v runmqakm &> /dev/null ]; then echo -e "${RED_BOLD}runmqakm could not be found${RESET}"; exit 1; fi;
echo -e "${YELLOW_BOLD}The optional Tools required are available as well, you can use the ACE & EEM section if you want to.${RESET}"