# gitshears

Bash script to help you to clean up you local branches.
Go to your local repository and run this script.

When you run the script, it will list all the local branches and its status :
- `[LOCAL]`   : the branch never been pushed to remote repository
- `[REMOTE]`  : the branch exist in remote repository
- `[DELETED]` : the branch was once pushed to remote repository, but it's been gone from the remote repository

Then, you can select which branch you want to delete using `space` and the hit `enter` to confirm it.

---

There are several options for this script :
#### `-a` options
This options will **automatically** deletes all the local branches with status `[DELETED]` without needing to select the branches one-by-one.  
Be careful, since the branches that will be deleted are not on remote repository anymore, the deleted branch cannot be restored.

#### `-d` options
This options will only showing list of local branches with status `[DELETED]` only.   
You still need to select which branch that you want to delete manually.

---

This script using [Bash Checkbox by HadiDotSh](https://github.com/HadiDotSh/bash-checkbox).
 
