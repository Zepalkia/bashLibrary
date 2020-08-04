#@DEPENDENCIES: git

# This function checks if a given branch name exists, this 'branch' can be a head, a tag or a remote branch
# arg0: The name of the branch we're looking for
# return: 0 if the branch exists, 1 otherwise
# Example:
#   if git_branchExists "master"; then
#     echo "Thankfully, the branch 'master' exists !"
#   fi
#@DEPENDS: git
function git_branchExists() {
  local __GIT_BRANCH_EXISTS__=1
  if [[ $# -eq 1 ]]; then
    __GIT_BRANCH_EXISTS__=0
    if ! git show-ref --verify --quiet "refs/heads/$1"; then
      if ! git show-ref --verify --quiet "refs/tags/$1"; then
        if ! git show-ref --verify --quiet "refs/remotes/origin/$1"; then
          __GIT_BRANCH_EXISTS__=1
          fi
      fi
    fi
  else
    bashlib_abort "$(caller)" "[branch name]"
  fi
  return $__GIT_BRANCH_EXISTS__
}

# This function loads into an array all the file differences of the current git repository, every entry of the array gives the kind of change and the file affected
# arg0: The name of the variable that will contain the array of changes
# Example:
#   git_loadDifferences result
#   for difference in ${result[@]}; do echo "Difference found: $difference"; done
#@DEPENDS: git
function git_loadDifferences() {
  if [[ $# -eq 1 ]]; then
    local -n __GIT_DIFFERENCES__=$1
    mapfile -t __GIT_DIFFERENCES__ < <(git status -s 2>/dev/null)
  else
    bashlib_abort "$(caller)" "[&result]"
  fi
}

# This function checks if the current git directory is behind the remote
# return: 0 if some changes can be pulled, 1 otherwise
# Example:
#   if git_hasRemoteChange; then
#     echo "Changes found, time to pull !"
#     git pull
#   fi
#@DEPENDS: git
function git_hasRemoteChange() {
  local __HAS_REMOTE_CHANGES__=1
  local result=""
  if git remote update &>/dev/null; then
    result=$(git status -uno | head -2 | tail -1)
    if [[ "$result" == *"commit"* ]]; then
      __HAS_REMOTE_CHANGES__=0
    fi
  fi
  return $__HAS_REMOTE_CHANGES__
}

# This function change the branch of the current git directory to the one specified.
# arg0: The branch to checkout
# arg1: A boolean telling if we want to revert the branch to a pristine status before changing (true) or not (false)
# return: 0 in case of success,
#         1 if the branch doesn't exists
#         2 if the checkout failed because of conflicts
# Note:
#   Be very careful than giving 'true' as arg1 to this function will reset ALL local changes, including new files, new directories, staged changes etc.., you
#   should call for a 'stash' before in case you want to keep them or resolve the conflicts manually before changing branch
#@DEPENDS: git
function git_changeBranch() {
  if [[ $# -eq 2 ]]; then
    local __BRANCH_CHANGE_SUCCESS__=1
    git fetch &>/dev/null
    if git_branchExists "$1"; then
      if [[ $2 == true ]]; then
        git reset --hard &>/dev/null
      fi
      if git checkout "$1" &>/dev/null; then
        __BRANCH_CHANGE_SUCCESS__=0
      else
        __BRANCH_CHANGE_SUCCESS__=2
      fi
    fi
  else
    bashlib_abort "$(caller)" "[target branch] [force checkout]"
  fi
  return $__BRANCH_CHANGE_SUCCESS__
}

# This function resets the currently cached credentials by git
# Note:
#   To erase all trace of the credentials entered by the user during the script execution, this function has to be called from inside the git directory of the
#   project, otherwise it will not remove everything
function git_resetCredentials() {
  git credential-cache exit
  if [[ -f ".git-credential-cache" ]]; then
    rm -rf .git-credential-cache &>/dev/null
  fi
}
