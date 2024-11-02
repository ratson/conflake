{ config, ... }@args:

{
  _module.args.moduleArgs = args // config._module.args;
}
