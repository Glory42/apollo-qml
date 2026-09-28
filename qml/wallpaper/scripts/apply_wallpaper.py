import os,shutil,subprocess,sys
source,target,transition,step,duration,fps,angle,pos,bezier,wave,invert_y,pywal_enabled=sys.argv[1:13]
if not source:
    sys.exit(2)
applied=source
if target:
    target=os.path.expanduser(target)
    if os.path.realpath(source) != os.path.realpath(target):
        os.makedirs(os.path.dirname(target) or '.',exist_ok=True)
        shutil.copy2(source,target)
    applied=target
cmd=['awww','img',applied,'--transition-type',transition,'--transition-step',step,'--transition-duration',duration,'--transition-fps',fps,'--transition-angle',angle,'--transition-pos',pos,'--transition-bezier',bezier,'--transition-wave',wave]
if invert_y == 'true':
    cmd.append('--invert-y')
result=subprocess.run(cmd,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
if result.returncode == 0 and pywal_enabled == 'true':
    if not shutil.which('wal'):
        print("Pywal is enabled, but the 'wal' command was not found in PATH.",file=sys.stderr)
        sys.exit(127)
    result=subprocess.run(['wal','-n','-q','-i',source])
sys.exit(result.returncode)
