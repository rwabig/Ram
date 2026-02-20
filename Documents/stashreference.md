he git stash command temporarily saves your uncommitted modifications (both staged and unstaged tracked files) to a local stack, allowing you to return to a clean working directory and switch branches or work on something else. The changes can be reapplied later. Stashes are local to your repository and are not transferred to the remote when you git push.
Common Commands and Usage
Here are the most common git stash commands and their functions:

    git stash or git stash push: Saves your local modifications and reverts the working directory to match the HEAD commit. You can add a descriptive message using the -m flag, e.g., git stash push -m "WIP on new feature". By default, it does not stash untracked (new) files, but you can include them with git stash -u or git stash --include-untracked.
    git stash list: Shows all the stashes you've saved, listed in a stack format (e.g., stash@{0}, stash@{1}).
    git stash apply: Reapplies the most recent stash to your working directory but keeps it in the stash list. To apply a specific stash, use its identifier: git stash apply stash@{1}.
    git stash pop: Reapplies the most recent stash and simultaneously removes it from the stash list. This is useful if you know you won't need to apply the same stash multiple times.
    git stash drop: Deletes a specific stash from the stack. If no stash is specified, it removes the most recent one.
    git stash clear: Removes all stashed entries from the list.
    git stash branch <newbranchname>: Creates a new branch from the commit on which the specified stash was originally created, and then applies (pops) the stashed changes onto it.

Typical Workflow
A common scenario is needing to switch branches for an urgent bug fix:

    You have uncommitted changes on feature-branch.
    Run git stash to save your work temporarily.
    Switch to the main or bugfix branch: git checkout main.
    Fix the bug, commit, and push your changes.
    Switch back to your original branch: git checkout feature-branch.
    Reapply your saved changes: git stash pop.

Best Practices:

    Use descriptive messages (git stash push -m "message") to easily identify stashes.
    git stash is meant for short-term, local storage of work-in-progress; for long-term work, it is better practice to create a dedicated branch and commit your changes.
