import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Screen recording with gpu-screen-recorder, tidied up with ffmpeg once it stops.
Item {
    id: root

    visible: false

    readonly property bool recording: recorder.running
    property string file: ""
    property real startedAt: 0
    property int elapsed: 0
    readonly property string elapsedText: {
        const minutes = Math.floor(elapsed / 60);
        const seconds = elapsed % 60;
        return (minutes < 10 ? "0" : "") + minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }

    signal saved(string file)
    signal failed(string message)

    // `target` is a monitor name or a region "WxH+X+Y" in logical pixels; `sound` is "none", "desktop" or "both".
    function start(target, sound) {
        if (recorder.running)
            return;
        root.file = Config.recordingDir + "/recording-" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".mp4";
        const audio = sound === "both" ? ["-a", "default_output|default_input", "-ac", "aac"]
            : (sound === "desktop" ? ["-a", "default_output", "-ac", "aac"] : []);
        recorder.command = ["sh", "-c", 'mkdir -p "$1" && shift && exec "$@"', "sh", Config.recordingDir,
            "gpu-screen-recorder", "-w", target, "-k", "auto", "-f", "60", "-fm", "cfr", "-fallback-cpu-encoding", "yes", "-o", root.file].concat(audio);
        root.elapsed = 0;
        root.startedAt = Date.now();
        recorder.running = true;
    }

    function stop() {
        // gpu-screen-recorder only writes a playable file when stopped with SIGINT.
        if (recorder.running)
            recorder.signal(2);
    }

    Timer {
        interval: 1000
        running: root.recording
        repeat: true
        onTriggered: root.elapsed = Math.round((Date.now() - root.startedAt) / 1000)
    }

    Process {
        id: recorder

        stderr: StdioCollector {
            id: errors
        }

        onExited: (exitCode) => {
            // Stopping with SIGINT is the normal way out, so only a quick failure with no file counts as one.
            if (exitCode !== 0 && Date.now() - root.startedAt < 3000) {
                root.failed(errors.text.trim().split("\n").slice(-1)[0] || "gpu-screen-recorder could not start");
                return;
            }
            tidy.command = ["sh", "-c", root.tidyScript, "sh", root.file];
            tidy.running = true;
        }
    }

    // Omarchy's clean-up: drop the first frame, and mute the opening pop and even out loudness when there is sound.
    readonly property string tidyScript: 'f=$1; [ -f "$f" ] || exit 1; out="${f%.mp4}-tidy.mp4"; codec="-c:v copy";'
        + ' ffprobe -v error -select_streams v:0 -read_intervals %+0.2 -show_entries packet=flags -of csv=p=0 "$f" 2>/dev/null | grep -q D && codec="-c:v libx264 -preset veryfast -crf 20";'
        + ' if ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$f" 2>/dev/null | grep -q audio; then'
        + ' ffmpeg -y -ss 0.1 -i "$f" $codec -af "volume=enable=\'lt(t,0.4)\':volume=0,afade=t=in:st=0.4:d=0.05,loudnorm=I=-14:TP=-1.5:LRA=11" "$out" -loglevel quiet;'
        + ' else ffmpeg -y -ss 0.1 -i "$f" $codec "$out" -loglevel quiet; fi && mv "$out" "$f" || rm -f "$out"; [ -f "$f" ]'

    Process {
        id: tidy

        onExited: (exitCode) => {
            if (exitCode === 0)
                root.saved(root.file);
            else
                root.failed("The recording could not be saved");
        }
    }
}
