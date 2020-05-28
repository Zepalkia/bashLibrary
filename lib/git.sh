#@DEPENDENCIES: git

# This function checks if a given branch name exists, this 'branch' can be a head, a tag or a remote branch
# arg0: The name of the branch we're looking for
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
          __GIT_BRANCH_EXISTS__=0
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

