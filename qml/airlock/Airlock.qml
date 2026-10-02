import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import ".."

// A real session lock: only a password PAM accepts unlocks it, and it stays locked if the shell dies.
Scope {
    id: root

    property var services: null
    readonly property bool isLocked: lock.locked

    // "", "checking" or "failed"
    property string status: ""
    // Notifications that arrived while locked; only the count is ever shown.
    property int missed: 0
    property string pending: ""

    signal opened()

    function lock() {
        if (lock.locked)
            return;
        root.status = "";
        root.missed = 0;
        lock.locked = true;
        root.opened();
    }

    function submit(password) {
        if (pam.active || password === "")
            return;
        root.pending = password;
        root.status = "checking";
        pam.start();
    }

    PamContext {
        id: pam

        configDirectory: Quickshell.shellPath("qml/airlock/pam")
        config: "password.conf"

        onPamMessage: {
            if (pam.responseRequired)
                pam.respond(root.pending);
        }

        onCompleted: (result) => {
            root.pending = "";
            if (result === PamResult.Success) {
                root.status = "";
                lock.locked = false;
            } else {
                root.status = "failed";
            }
        }

        onError: {
            root.pending = "";
            root.status = "failed";
        }
    }

    Connections {
        target: root.services ? root.services.center : null

        function onReceived() {
            if (lock.locked)
                root.missed += 1;
        }
    }

    WlSessionLock {
        id: lock

        WlSessionLockSurface {
            color: Theme.hull

            AirlockScreen {
                anchors.fill: parent
                services: root.services
                status: root.status
                missed: root.missed
                onSubmitted: (password) => root.submit(password)
            }
        }
    }
}
