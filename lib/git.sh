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
          __GIT_BRANCH_EXISTS__=1
          fi
      fi
    fi
  else
    false
  fi
  return $__GIT_BRANCH_EXISTS__
}
