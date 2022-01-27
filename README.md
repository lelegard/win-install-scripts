## Scripts to automate the installation of various tools on Windows

Each PowerShell script downloads and installs some software for Windows.
Each downloaded software is either open source or free to use.

These scripts are useful to automate the setup of a software environment,
typically in a CI/CD pipeline.

Each script is autonomous and can be individually extracted for reuse
in another project (liberal BSD-2-Clause license).

By default, when a script is run from the Windows explorer, it pops up
a PowerShell window, performs the download and installation and finally
waits for the user to press <enter> before closing the window. When
used in an automated scripted environment, use option `-NoPause` to
avoid the final interaction.

Each installation script accepts the following options.

| Option              | Description
|---------------------|--------------------------------------------------
| -Destination _path_ | Specify a local directory where the package will be downloaded. By default, use the downloads folder for the current user.
| -ForceDownload      | Force a download even if the package is already downloaded.
| -GitHubActions      | When used in a GitHub Action workflow, make sure that the required environment variables are propagated to subsequent jobs.
| -NoInstall          | Do not install the package. Only download it. By default, the package is installed.
| -NoPause            | Do not wait for the user to press <enter> at end of execution. By default, execute a `pause` instruction at the end of execution, which is useful when the script was run from Windows Explorer.

Note on executing PowerShell scripts from the Windows Explorer:
The default action for double-click on a `.ps1` file in Windows Explorer is to
edit the script file using notepad. This is not very convenient. The registry
file `WindowsPowerShell.reg` changes this to execute the PowerShell script
on double-click. This is more consistent with `.exe` files which are executed.
