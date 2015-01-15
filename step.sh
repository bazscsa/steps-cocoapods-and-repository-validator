#!/bin/bash

THIS_SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${THIS_SCRIPTDIR}/_utils.sh"
source "${THIS_SCRIPTDIR}/_formatted_output.sh"

# init / cleanup the formatted output
echo "" > "${formatted_output_file_path}"



if [ -z "${BITRISE_SOURCE_DIR}" ]; then
  write_section_to_formatted_output "# Error"
  write_section_start_to_formatted_output '* BITRISE_SOURCE_DIR input is missing'
  exit 1
fi

# Update Cocoapods
if [[ "${IS_UPDATE_COCOAPODS}" != "false" ]] ; then
  print_and_do_command_exit_on_error bash "${THIS_SCRIPTDIR}/steps-cocoapods-update/step.sh"
else
  write_section_to_formatted_output "*Skipping Cocoapods version update*"
fi

print_and_do_command_exit_on_error cd "${BITRISE_SOURCE_DIR}"

if [ -n "${GATHER_PROJECTS}" ]; then
  write_section_to_formatted_output "# Gathering project configurations"
  # create/cleanup ~/.schemes file
  echo "" > ~/.schemes

  detected_branches=$(git branch -r | grep -v -- "->")
  echo " (i) detected_branches: ${detected_branches}"
  for branch in ${detected_branches} ; do
    echo "-> Switching to branch: ${branch}"
    # remove every file before switch; except the .git folder
    print_and_do_command_exit_on_error find . -not -path '*.git/*' -not -path '*.git' -delete
    # remove the prefix "origin/" from the branch name
    branch_without_remote=$(printf "%s" "${branch}" | cut -c 8-)
    echo "Local branch: ${branch_without_remote}"
    # switch to branch
    print_and_do_command_exit_on_error git checkout -f "${branch_without_remote}"
    
    print_and_do_command_exit_on_error bash "${THIS_SCRIPTDIR}/run_pod_install.sh"
    print_and_do_command_exit_on_error bash "${THIS_SCRIPTDIR}/find_schemes.sh" "${branch_without_remote}"
    echo "-> Finished on branch: ${branch}"
  done
else
  write_section_to_formatted_output "# Run pod install"
  print_and_do_command_exit_on_error bash "${THIS_SCRIPTDIR}/run_pod_install.sh"
fi

exit 0
