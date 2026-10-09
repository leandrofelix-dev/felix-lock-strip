import QtCore
import QtQuick
import QtQuick.Window
import SddmComponents 2.0
import "i18n"

Rectangle {
    id: root

    readonly property real s: Screen.height / 768
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property var wall: ({})
    property var namedScheme: null
    property bool matchWallpaper: true
    readonly property string themeModeHint: (typeof config !== "undefined" && config.themeMode) ? ("" + config.themeMode) : ""
    readonly property bool isLight: {
        var surf = "";
        if (root.namedScheme && root.usable(root.namedScheme.surface))
            surf = root.namedScheme.surface;
        else if (root.matchWallpaper && root.usable(root.wall.surface))
            surf = root.wall.surface;
        if (root.usable(surf))
            return root.hexLum(surf) > 0.45;

        if (root.themeModeHint === "light")
            return true;

        return false;
    }
    readonly property color _fbBg: root.isLight ? "#f3ede1" : "#0f0c07"
    readonly property color _fbSurface: root.isLight ? "#ebe4d6" : "#16110b"
    readonly property color _fbSurfaceHi: root.isLight ? "#e0d6c4" : "#1b150e"
    readonly property color _fbBright: root.isLight ? "#0f0c07" : "#f3ede1"
    readonly property color _fbCream: root.isLight ? "#1b150e" : "#e6dccb"
    readonly property color _fbDim: root.isLight ? "#5c5249" : "#8f8770"
    readonly property color _fbFaint: root.isLight ? "#8f8770" : "#5c5249"
    readonly property color _fbBrand: "#e2342a"
    readonly property color _fbBad: "#e05a5a"
    readonly property color bg: root.role("surfaceContainerLowest", root.role("background", root._fbBg))
    readonly property color surface: root.role("surface", root._fbSurface)
    readonly property color surfaceHi: root.role("surfaceContainer", root._fbSurfaceHi)
    readonly property color bright: root.role("onSurface", root._fbBright)
    readonly property color cream: root.role("onSurface", root._fbCream)
    readonly property color dim: root.role("onSurfaceVariant", root._fbDim)
    readonly property color faint: root.role("outline", root._fbFaint)
    readonly property color line: Qt.rgba(root.bright.r, root.bright.g, root.bright.b, 0.14)
    readonly property color lineStrong: Qt.rgba(root.bright.r, root.bright.g, root.bright.b, 0.4)
    readonly property color brand: root.role("primary", root._fbBrand)
    readonly property color gold: "#d9a441"
    readonly property color bad: root.role("error", root._fbBad)
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string uiFont: "Space Grotesk"
    readonly property string displayFont: "Space Grotesk"
    readonly property bool clockAwake: ((typeof sddm !== "undefined") && sddm.fingerprintHint === true) || Window.active
    readonly property bool fpVisible: (typeof sddm !== "undefined") && sddm.fingerprintHint === true && sddm.fingerprintReady === true
    readonly property var fpState: typeof sddm !== "undefined" ? (sddm.fingerprintState || "idle") : "idle"
    readonly property string fpHintText: {
        if (root.fpState === "success")
            return I18n.tr("ACCESS GRANTED ✦");

        if (root.fpState === "fail")
            return I18n.tr("SCAN DENIED ✦ TYPE YOUR KEY");

        if (root.fpState === "scanning")
            return I18n.tr("SENSOR ACTIVE ✦ TOUCH OR TYPE");

        return I18n.tr("TOUCH SENSOR ✦ TO UNLOCK");
    }
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property real uiOpacity: 0
    property string authInfo: ""
    property string errorText: ""
    property bool _unlocked: false
    readonly property bool fidoInfo: authInfo.toLowerCase().indexOf("fido") >= 0 || authInfo.toLowerCase().indexOf("authenticator") >= 0 || authInfo.toLowerCase().indexOf("pin") >= 0
    readonly property string inputHint: authInfo !== "" ? authInfo.toUpperCase() : I18n.tr("TYPE PASSWORD OR FIDO PIN")
    property int curH: new Date().getHours()
    property int curM: new Date().getMinutes()
    property int curS: new Date().getSeconds()
    readonly property real stripHeight: 132 * s

    function usable(v) {
        return typeof v === "string" && v.length > 0;
    }

    function _readFile(path) {
        if (!path)
            return "";

        var xhr = new XMLHttpRequest();
        try {
            xhr.open("GET", "file://" + path, false);
            xhr.send();
            if (xhr.status === 200 || xhr.status === 0)
                return xhr.responseText || "";

        } catch (e) {
        }
        return "";
    }

    function _homeDir() {
        try {
            var h = StandardPaths.writableLocation(StandardPaths.HomeLocation);
            if (h && h.length)
                return ("" + h).replace(/^file:\/\//, "");

        } catch (e) {
        }
        if (typeof userModel !== "undefined") {
            try {
                if (userModel.count > 0) {
                    var item = userModel.get(0);
                    if (item && item.homeDir)
                        return item.homeDir;

                }
            } catch (e2) {
            }
            if (userModel.lastUser)
                return "/home/" + userModel.lastUser;

        }
        return "";
    }

    function role(key, base) {
        if (root.namedScheme && root.usable(root.namedScheme[key]))
            return root.namedScheme[key];

        if (root.matchWallpaper && root.usable(root.wall[key]))
            return root.wall[key];

        return base;
    }

    function hexLum(hex) {
        function chan(i) {
            var c = parseInt(hex.substr(i, 2), 16) / 255;
            return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
        }

        if (!root.usable(hex) || hex.charAt(0) !== "#" || hex.length < 7)
            return 0;

        return 0.2126 * chan(1) + 0.7152 * chan(3) + 0.0722 * chan(5);
    }

    function refreshPalette() {
        var home = root._homeDir();
        if (!home)
            return ;

        var cache = home + "/.cache/ryoku";
        var conf = home + "/.config/ryoku";
        try {
            var tw = root._readFile(cache + "/colors.json");
            root.wall = tw && tw.length ? (JSON.parse(tw) || {}) : {};
        } catch (e) {
            root.wall = ({});
        }
        var pal = null;
        try {
            var ts = root._readFile(conf + "/shell.json");
            if (ts) {
                var so = JSON.parse(ts);
                if (so && typeof so.themePalette === "object" && so.themePalette !== null)
                    pal = so.themePalette;

            }
        } catch (e2) {
            pal = null;
        }
        root.namedScheme = pal;
        try {
            var tt = root._readFile(conf + "/theme.json");
            var to = tt ? JSON.parse(tt) : null;
            root.matchWallpaper = (to && typeof to.followWallpaper === "boolean") ? to.followWallpaper : true;
        } catch (e3) {
            root.matchWallpaper = true;
        }
    }

    function capitalizeFirst(str) {
        if (!str)
            return "";

        return str.charAt(0).toUpperCase() + str.slice(1);
    }

    function doLogin() {
        if (root._unlocked)
            return ;

        if (passInput.text.length === 0) {
            root.errorText = "";
            passInput.forceActiveFocus();
            return ;
        }
        root._unlocked = true;
        root.authInfo = "";
        root.errorText = "";
        var uname = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : "user");
        if (typeof sddm !== "undefined")
            sddm.login(uname, passInput.text, root.sessionIndex);

        authWatchdog.restart();
    }

    function preferredSessionIndex() {
        if (typeof sessionModel === "undefined")
            return 0;

        var want = (typeof sessionModel.desktopName === "string") ? sessionModel.desktopName : "";
        var exact = -1, loose = -1;
        for (var i = 0; i < sessionScan.count; i++) {
            var it = sessionScan.itemAt(i);
            if (!it)
                continue;

            var low = (it.sName || "").toLowerCase();
            if (low.indexOf("uwsm") >= 0)
                continue;

            if (want !== "" && low === want)
                exact = i;
            else if (want !== "" && low.indexOf(want) >= 0 && loose < 0)
                loose = i;
        }
        if (exact >= 0)
            return exact;

        if (loose >= 0)
            return loose;

        return (sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0;
    }

    width: Screen.width
    height: Screen.height
    color: root.bg
    Component.onCompleted: {
        root.refreshPalette();
        if (typeof keyboard !== "undefined")
            keyboard.numLock = true;

        if (typeof sessionModel !== "undefined")
            root.sessionIndex = preferredSessionIndex();

        fadeIn.start();
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
        onClicked: passInput.forceActiveFocus()
    }

    HoverHandler {
        id: swPointer

        enabled: !root.isQuickshell
    }

    Canvas {
        id: swCursor

        width: 20 * root.s
        height: 20 * root.s
        z: 2e+06
        visible: !root.isQuickshell && swPointer.hovered
        x: swPointer.point.position.x
        y: swPointer.point.position.y
        antialiasing: true
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.scale(root.s, root.s);
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(0, 12.5);
            ctx.lineTo(3.1, 9.8);
            ctx.lineTo(5.1, 14.8);
            ctx.lineTo(7, 14);
            ctx.lineTo(5.1, 9);
            ctx.lineTo(8.6, 9);
            ctx.closePath();
            ctx.fillStyle = "" + root.bright;
            ctx.fill();
            ctx.lineWidth = 1;
            ctx.strokeStyle = "" + root.bg;
            ctx.stroke();
        }

        Connections {
            function onBrightChanged() {
                swCursor.requestPaint();
            }

            function onBgChanged() {
                swCursor.requestPaint();
            }

            target: root
        }

    }

    Timer {
        interval: 1000
        running: root.clockAwake
        repeat: true
        onTriggered: {
            var d = new Date();
            root.curH = d.getHours();
            root.curM = d.getMinutes();
            root.curS = d.getSeconds();
        }
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        onTriggered: root.refreshPalette()
    }

    ListView {
        id: userHelper

        width: 1
        height: 1
        opacity: 0
        currentIndex: root.userIndex
        model: typeof userModel !== "undefined" ? userModel : null

        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
        }

    }

    ListView {
        id: sessionHelper

        width: 1
        height: 1
        opacity: 0
        currentIndex: root.sessionIndex
        model: typeof sessionModel !== "undefined" ? sessionModel : null

        delegate: Item {
            property string sName: model.name || ""
        }

    }

    Timer {
        interval: 300
        running: true
        onTriggered: passInput.forceActiveFocus()
    }

    NumberAnimation {
        id: fadeIn

        target: root
        property: "uiOpacity"
        to: 1
        duration: 360
        easing.type: Easing.OutCubic
    }

    Rectangle {
        anchors.fill: parent
        color: root.bg
    }

    Rectangle {
        anchors.fill: parent
        opacity: 0.85

        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.surface
            }

            GradientStop {
                position: 1
                color: root.bg
            }

        }

    }

    // Centered clock stack (distinct from felix-lock left column)
    Column {
        id: clockStack

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: authStrip.top
        anchors.bottomMargin: 48 * s
        spacing: 10 * s
        opacity: root.uiOpacity
        width: Math.min(520 * s, parent.width - 80 * s)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: I18n.tr("TIME INDEX").toUpperCase()
            color: root.faint
            font.family: root.mono
            font.pixelSize: 8 * s
            font.letterSpacing: 4 * s
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: String(root.curH).padStart(2, "0") + ":" + String(root.curM).padStart(2, "0")
            color: root.bright
            font.family: root.displayFont
            font.pixelSize: 96 * s
            font.weight: Font.Light
            font.letterSpacing: -2 * s
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12 * s

            Rectangle {
                width: 28 * s
                height: 2 * s
                color: root.brand
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: String(root.curS).padStart(2, "0")
                color: root.dim
                font.family: root.mono
                font.pixelSize: 11 * s
                font.letterSpacing: 3 * s
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 28 * s
                height: 2 * s
                color: root.lineStrong
                anchors.verticalCenter: parent.verticalCenter
            }

        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(new Date(), "dddd · MMMM d, yyyy").toUpperCase()
            color: root.cream
            font.family: root.uiFont
            font.pixelSize: 13 * s
            font.letterSpacing: 3.5 * s
            font.weight: Font.Medium
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(new Date(), "yyyy · MM · dd").toUpperCase()
            color: root.dim
            font.family: root.mono
            font.pixelSize: 8 * s
            font.letterSpacing: 2.5 * s
        }

    }

    // Full-width bottom authentication strip
    Item {
        id: authStrip

        property real shakeOffset: 0

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: authStrip.shakeOffset
        height: root.stripHeight
        opacity: root.uiOpacity

        Rectangle {
            anchors.fill: parent
            color: root.surfaceHi
            border.color: root.lineStrong
            border.width: 1 * s
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 2 * s
            color: root.brand
            opacity: 0.85
        }

        Column {
            anchors.fill: parent
            anchors.margins: 18 * s
            spacing: 0

            Row {
                width: parent.width
                spacing: 16 * s

                Column {
                    width: Math.min(220 * s, parent.width * 0.28)
                    spacing: 4 * s

                    Row {
                        spacing: 8 * s

                        Text {
                            text: "01"
                            color: root.brand
                            font.family: root.mono
                            font.pixelSize: 8 * s
                            font.letterSpacing: 1.5 * s
                        }

                        Text {
                            text: I18n.tr("IDENTITY").toUpperCase()
                            color: root.dim
                            font.family: root.mono
                            font.pixelSize: 8 * s
                            font.letterSpacing: 2.5 * s
                        }

                    }

                    Item {
                        width: parent.width
                        height: userNameDisp.implicitHeight

                        Text {
                            id: userNameDisp

                            width: parent.width
                            text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : ((typeof userModel !== "undefined" && userModel.lastUser) ? capitalizeFirst(userModel.lastUser) : I18n.tr("USER"))).toUpperCase()
                            color: uMa.containsMouse ? root.bright : root.cream
                            font.family: root.uiFont
                            font.pixelSize: 15 * s
                            font.weight: Font.Medium
                            font.letterSpacing: 2.5 * s
                            elide: Text.ElideRight

                            Behavior on color {
                                ColorAnimation {
                                    duration: 180
                                }

                            }

                        }

                        MouseArea {
                            id: uMa

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof userModel !== "undefined" && userModel.rowCount() > 0)
                                    root.userIndex = (root.userIndex + 1) % userModel.rowCount();

                            }
                        }

                    }

                    Text {
                        width: parent.width
                        text: (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : ((typeof userModel !== "undefined" && userModel.lastUser) ? userModel.lastUser : "user")
                        color: root.faint
                        font.family: root.mono
                        font.pixelSize: 8 * s
                        font.letterSpacing: 1.5 * s
                    }

                }

                Rectangle {
                    width: 1 * s
                    height: 52 * s
                    color: root.line
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    width: parent.width - 220 * s - 16 * s - 1 * s - 120 * s
                    spacing: 6 * s
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: fpHint

                        width: parent.width
                        height: root.fpVisible ? 12 * s : 0
                        visible: root.fpVisible
                        text: root.fpHintText
                        color: root.fpState === "fail" ? root.bad : (root.fpState === "scanning" || root.fpState === "success" ? root.bright : root.dim)
                        font.family: root.mono
                        font.pixelSize: 8 * s
                        font.letterSpacing: 1.5 * s
                        opacity: root.fpState === "scanning" ? fpPulseVal.value : 1

                        Behavior on height {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                    Item {
                        width: parent.width
                        height: 28 * s

                        TextInput {
                            id: passInput

                            anchors.fill: parent
                            anchors.bottomMargin: 5 * s
                            echoMode: TextInput.Password
                            passwordCharacter: "·"
                            color: root.bright
                            font.family: root.mono
                            font.pixelSize: 12 * s
                            font.letterSpacing: 6 * s
                            focus: true
                            cursorVisible: false
                            Keys.onReturnPressed: doLogin()
                            Keys.onEnterPressed: doLogin()

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.inputHint
                                color: root.fidoInfo ? root.gold : root.faint
                                font.family: root.mono
                                font.pixelSize: 8 * s
                                font.letterSpacing: 1.5 * s
                                opacity: passInput.text.length === 0 ? 0.85 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }

                                }

                            }

                            Rectangle {
                                id: needle

                                width: 1.5 * s
                                height: 11 * s
                                color: root.brand
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, passInput.cursorRectangle.x)
                                visible: passInput.focus && (passInput.text.length > 0 || passInput.activeFocus)

                                SequentialAnimation {
                                    loops: Animation.Infinite
                                    running: needle.visible

                                    NumberAnimation {
                                        target: needle
                                        property: "opacity"
                                        from: 1
                                        to: 0.15
                                        duration: 420
                                    }

                                    NumberAnimation {
                                        target: needle
                                        property: "opacity"
                                        from: 0.15
                                        to: 1
                                        duration: 420
                                    }

                                }

                            }

                            cursorDelegate: Item {
                                width: 0
                                height: 0
                            }

                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: passInput.activeFocus ? 2 * s : 1 * s
                            color: passInput.activeFocus ? root.brand : root.line

                            Behavior on color {
                                ColorAnimation {
                                    duration: 180
                                }

                            }

                            Behavior on height {
                                NumberAnimation {
                                    duration: 160
                                }

                            }

                        }

                    }

                    Text {
                        id: errLabel

                        width: parent.width
                        height: root.errorText !== "" ? 14 * s : 0
                        text: root.errorText
                        color: root.bad
                        font.family: root.mono
                        font.pixelSize: 8 * s
                        font.letterSpacing: 1.5 * s
                        elide: Text.ElideRight
                    }

                }

                Item {
                    width: 120 * s
                    height: parent.height

                    Column {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6 * s

                        Row {
                            spacing: 8 * s
                            anchors.right: parent.right

                            Text {
                                id: unlockLabel

                                text: passInput.text.length > 0 ? I18n.tr("UNLOCK") : I18n.tr("ENTER KEY")
                                color: unlockMa.containsMouse ? root.brand : root.bright
                                font.family: root.mono
                                font.pixelSize: 9 * s
                                font.letterSpacing: 3 * s
                                font.weight: Font.DemiBold

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 160
                                    }

                                }

                            }

                            Text {
                                text: "→"
                                color: root.brand
                                font.family: root.mono
                                font.pixelSize: 12 * s
                                opacity: unlockMa.containsMouse ? 1 : 0.35

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 160
                                    }

                                }

                            }

                        }

                        MouseArea {
                            id: unlockMa

                            anchors.fill: parent.parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: doLogin()
                        }

                    }

                }

            }

            Item {
                width: 1
                height: 10 * s
            }

            Rectangle {
                width: parent.width
                height: 1 * s
                color: root.line
            }

            Item {
                width: 1
                height: 8 * s
            }

            Row {
                id: actionRow

                spacing: 0
                width: parent.width

                Item {
                    width: actionRow.width / 3
                    height: 16 * s
                    visible: !root.isQuickshell

                    Text {
                        anchors.centerIn: parent
                        text: sessionHelper.currentItem ? sessionHelper.currentItem.sName : I18n.tr("Session")
                        color: sessionMa.containsMouse ? root.bright : root.dim
                        font.family: root.mono
                        font.pixelSize: 8 * s
                        font.letterSpacing: 1.5 * s
                    }

                    MouseArea {
                        id: sessionMa

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0)
                                root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount();

                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1 * s
                        height: 8 * s
                        color: root.line
                    }

                }

                Item {
                    width: actionRow.width / 3
                    height: 16 * s

                    Text {
                        anchors.centerIn: parent
                        text: I18n.tr("Reboot")
                        color: rebootMa.containsMouse ? root.bright : root.dim
                        font.family: root.mono
                        font.pixelSize: 8 * s
                        font.letterSpacing: 1.5 * s
                    }

                    MouseArea {
                        id: rebootMa

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof sddm !== "undefined")
                                sddm.reboot();

                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1 * s
                        height: 8 * s
                        color: root.line
                    }

                }

                Item {
                    width: actionRow.width / 3
                    height: 16 * s

                    Text {
                        anchors.centerIn: parent
                        text: I18n.tr("Shutdown")
                        color: powerMa.containsMouse ? root.bright : root.dim
                        font.family: root.mono
                        font.pixelSize: 8 * s
                        font.letterSpacing: 1.5 * s
                    }

                    MouseArea {
                        id: powerMa

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof sddm !== "undefined")
                                sddm.powerOff();

                        }
                    }

                }

            }

        }

    }

    SequentialAnimation {
        id: fpPulse

        loops: Animation.Infinite
        running: root.fpVisible && root.fpState === "scanning"

        NumberAnimation {
            target: fpPulseVal
            property: "value"
            from: 1
            to: 0.4
            duration: 600
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: fpPulseVal
            property: "value"
            from: 0.4
            to: 1
            duration: 600
            easing.type: Easing.InOutSine
        }

    }

    Item {
        id: fpPulseVal

        property real value: 1
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 28 * s
        text: "RYOKU  ·  " + I18n.tr("LOCK").toUpperCase() + "  ·  STRIP"
        color: root.dim
        font.family: root.mono
        font.pixelSize: 8 * s
        font.letterSpacing: 3 * s
        opacity: root.uiOpacity * 0.9
    }

    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 40 * s
        anchors.topMargin: 28 * s
        text: Qt.formatDate(new Date(), "yyyy · MM · dd").toUpperCase()
        color: root.faint
        font.family: root.mono
        font.pixelSize: 8 * s
        font.letterSpacing: 2.5 * s
        opacity: root.uiOpacity * 0.85
    }

    Connections {
        function onInformationMessage(message) {
            root.authInfo = message || "";
            root.errorText = root.authInfo.toUpperCase();
            passInput.forceActiveFocus();
        }

        function onErrorMessage(message) {
            root.errorText = (message || "").toUpperCase();
        }

        function onLoginSucceeded() {
            authWatchdog.stop();
            root.errorText = "";
        }

        function onLoginFailed() {
            authWatchdog.stop();
            root._unlocked = false;
            root.authInfo = "";
            root.errorText = I18n.tr("ACCESS DENIED");
            passInput.text = "";
            passInput.forceActiveFocus();
            shake.start();
        }

        target: typeof sddm !== "undefined" ? sddm : null
        ignoreUnknownSignals: true
    }

    SequentialAnimation {
        id: shake

        NumberAnimation {
            target: authStrip
            property: "shakeOffset"
            to: 8 * s
            duration: 45
        }

        NumberAnimation {
            target: authStrip
            property: "shakeOffset"
            to: -8 * s
            duration: 45
        }

        NumberAnimation {
            target: authStrip
            property: "shakeOffset"
            to: 6 * s
            duration: 45
        }

        NumberAnimation {
            target: authStrip
            property: "shakeOffset"
            to: 0
            duration: 45
        }

    }

    Timer {
        id: authWatchdog

        interval: 8000
        onTriggered: {
            root._unlocked = false;
            root.authInfo = "";
            root.errorText = "";
            passInput.text = "";
            passInput.forceActiveFocus();
        }
    }

    Item {
        visible: false

        Repeater {
            id: sessionScan

            model: (typeof sessionModel !== "undefined") ? sessionModel : null

            delegate: Item {
                property string sName: model.name || ""
            }

        }

    }

}
