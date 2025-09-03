{ }:
{
  mkOpenAgent = { appName, runAtLoad ? true, background ? false }: {
    serviceConfig = {
      ProgramArguments = if background
        then [ "/usr/bin/open" "-gj" "-a" appName ]
        else [ "/usr/bin/open" "-a" appName ];
      RunAtLoad = runAtLoad;
      KeepAlive = false;
    };
  };
}


