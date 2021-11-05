I'm trying to fix incremental sync in the built-in client once and for all, removing all the hacks and workarounds I did the first time around.

Features:

1. Sync debugger 
Start a multi-pane debugger, will show you the previous/current buffer in the bottom two panes, and the range computed by the diffing mechanism for sending to the server on the upper right pane.
```
bash start.sh
```

2. Incremental sync tests
Run the plenary test suite, will start a separate neovim instance to run the plenary tests. Currently, only checks against the current built-in client's mechanisms (which is wrong in several cases).
```
bash test.sh
```
