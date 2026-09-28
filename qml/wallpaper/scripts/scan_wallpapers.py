import json,os,sys
wallpaper_dir=os.path.expanduser(sys.argv[1])
exts={'.jpg','.jpeg','.png','.webp','.gif','.avif','.tiff','.bmp'}
def record(path):
    st=os.stat(path)
    return {'filePath':path,'fileName':os.path.basename(path),'mtime':st.st_mtime_ns,'size':st.st_size}
fresh=[]
if os.path.isdir(wallpaper_dir):
    for entry in sorted(os.scandir(wallpaper_dir),key=lambda e:e.name.lower()):
        if entry.is_file() and os.path.splitext(entry.name)[1].lower() in exts:
            try:
                print(json.dumps(record(entry.path),separators=(',',':')),flush=True)
            except OSError:
                pass
