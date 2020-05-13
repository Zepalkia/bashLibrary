#@DEPENDENCIES: git

# This function checks if a given branch name exists, this 'branch' can be a head, a tag or a remote branch
# arg0: The name of the branch we're looking for
# arg1: The name of the variable that will contain the result (boolean)
# Example:
#   git_branchExists "master" result
#   if [[ $result == true ]]; then
#     echo "Thankfully, the branch 'master' exists !"
#   fi
#@DEPENDS: git
function git_branchExists() {
  if [[ $# -eq 2 ]]; then
    local -n __GIT_BRANCH_EXISTS__=$2
    __GIT_BRANCH_EXISTS__=true
    if ! git show-ref --verify --quiet "refs/heads/$1"; then
      if ! git show-ref --verify --quiet "refs/tags/$1"; then
        if ! git show-ref --verify --quiet "refs/remotes/origin/$1"; then
          __GIT_BRANCH_EXISTS__=false
          fi
      fi
    fi
  else
    false
  fi
}
