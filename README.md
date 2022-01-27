## Scripts to automate the installation of various tools on Windows

Each PowerShell script downloads and installs some software for Windows.
Each script accepts the following options.

| Option              | Description
|---------------------|--------------------------------------------------
| -Destination _path_ | Specify a local directory where the package will be downloaded. By default, use the downloads folder for the current user.
| -ForceDownload      | Force a download even if the package is already downloaded.
| -GitHubActions      | When used in a GitHub Action workflow, make sure that the required environment variables are propagated to subsequent jobs.
| -NoInstall          | Do not install the package. Only download it. By default, the package is installed.
| -NoPause            | Do not wait for the user to press <enter> at end of execution. By default, execute a `pause` instruction at the end of execution, which is useful when the script was run from Windows Explorer.
