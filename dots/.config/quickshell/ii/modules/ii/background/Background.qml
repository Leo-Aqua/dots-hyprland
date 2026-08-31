pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.models
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris

import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.weather

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: bgRoot

        required property var modelData

        property real maxVisualizerValue: 1000 // Max value in the data points
        property int visualizerSmoothing: 2 // Number of points to average for smoothing
        readonly property MprisPlayer activePlayer: MprisController.activePlayer
        readonly property var realPlayers: MprisController.players
        readonly property var meaningfulPlayers: filterDuplicatePlayers(realPlayers)
        property list<real> visualizerPoints: []

        property int currentVolume: 0

        // Hide when fullscreen
        property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
        property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
        visible: GlobalStates.screenLocked || (!(activeWorkspaceWithFullscreen != undefined)) || !Config?.options.background.hideWhenFullscreen

        // Workspaces
        property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        property list<var> relevantWindows: HyprlandData.windowList.filter(win => win.monitor == monitor?.id && win.workspace.id >= 0).sort((a, b) => a.workspace.id - b.workspace.id)
        property int firstWorkspaceId: relevantWindows[0]?.workspace.id || 1
        property int lastWorkspaceId: relevantWindows[relevantWindows.length - 1]?.workspace.id || 10
        property int workspaceChunkSize: Config?.options.bar.workspaces.shown ?? 10
        property int totalWorkspaces: Math.ceil(lastWorkspaceId / workspaceChunkSize) * workspaceChunkSize
        // Wallpaper
        property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || Config.options.background.wallpaperPath.endsWith(".webm") || Config.options.background.wallpaperPath.endsWith(".mkv") || Config.options.background.wallpaperPath.endsWith(".avi") || Config.options.background.wallpaperPath.endsWith(".mov")
        property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
        property bool wallpaperSafetyTriggered: {
            const enabled = Config.options.workSafety.enable.wallpaper;
            const sensitiveWallpaper = (CF.StringUtils.stringListContainsSubstring(wallpaperPath.toLowerCase(), Config.options.workSafety.triggerCondition.fileKeywords));
            const sensitiveNetwork = (CF.StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
            return enabled && sensitiveWallpaper && sensitiveNetwork;
        }
        readonly property real parallaxRation: Config.options.background.parallax.workspaceZoom
        property real minSuitableScale: 1 // Some reasonable init, to be updated
        property real effectiveWallpaperScale: minSuitableScale * parallaxRation
        property int wallpaperWidth: modelData.width // Some reasonable init value, to be updated
        property int wallpaperHeight: modelData.height // Some reasonable init value, to be updated
        property real scaledWallpaperWidth: wallpaperWidth * effectiveWallpaperScale
        property real scaledWallpaperHeight: wallpaperHeight * effectiveWallpaperScale
        property real parallaxTotalPixelsX: Math.max(0, scaledWallpaperWidth - screen.width)
        property real parallaxTotalPixelsY: Math.max(0, scaledWallpaperHeight - screen.height)
        readonly property bool verticalParallax: (Config.options.background.parallax.autoVertical && wallpaperHeight > wallpaperWidth) || Config.options.background.parallax.vertical
        // Colors
        property bool shouldBlur: (GlobalStates.screenLocked && Config.options.lock.blur.enable)
        property color dominantColor: Appearance.colors.colPrimary // Default, to be changed

        // MPRIS Artwork & Color Quantization
        property var activeArtUrl: bgRoot.activePlayer?.trackArtUrl ?? ""
        property string artDownloadLocation: Directories.coverArt
        property string artFileName: bgRoot.activeArtUrl ? Qt.md5(bgRoot.activeArtUrl) : ""
        property string artFilePath: bgRoot.artFileName ? `${bgRoot.artDownloadLocation}/${bgRoot.artFileName}` : ""

        property bool artDownloaded: false
        // Use Qt.resolvedUrl exactly like playerController
        property string displayedArtFilePath: bgRoot.artDownloaded ? Qt.resolvedUrl(bgRoot.artFilePath) : ""

        // Exact color binding from playerController
        property color artDominantColor: CF.ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer

        onArtFilePathChanged: {
            if (bgRoot.activeArtUrl.length === 0) {
                bgRoot.artDominantColor = Appearance.m3colors.m3secondaryContainer;
                return;
            }

            // Binding does not work in Process, assign manually
            coverArtDownloader.targetFile = bgRoot.activeArtUrl;
            coverArtDownloader.targetPath = bgRoot.artFilePath;

            // Trigger download
            bgRoot.artDownloaded = false;
            coverArtDownloader.running = true;
        }

        Process { // Cover art downloader
            id: coverArtDownloader
            property string targetFile: ""
            property string targetPath: ""

            command: ["bash", "-c", `[ -f "${targetPath}" ] || curl -4 -sSL '${targetFile}' -o '${targetPath}'`]
            onExited: (exitCode, exitStatus) => {
                bgRoot.artDownloaded = true;
            }
        }

        ColorQuantizer {
            id: colorQuantizer
            source: bgRoot.displayedArtFilePath
            depth: 0
            rescaleSize: 1
        }

        property QtObject blendedColors: AdaptedMaterialScheme {
            color: bgRoot.artDominantColor
        }

        // Execute the script safely only when the color has updated and the image is ready
        onArtDominantColorChanged: {
            if (bgRoot.artDownloaded && bgRoot.activePlayer && bgRoot.activePlayer.isPlaying) {
                Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --image "${bgRoot.artFilePath}" --noswitch`]);
            }
        }

        Connections {
            target: bgRoot.activePlayer ?? null
            enabled: bgRoot.activePlayer !== null

            function onIsPlayingChanged() {
                if (bgRoot.activePlayer.isPlaying) {
                    // Prevent running the script until the artwork is successfully downloaded.
                    if (bgRoot.artDownloaded && bgRoot.artFilePath.length > 0) {
                        Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --image "${bgRoot.artFilePath}" --noswitch`]);
                    }
                } else {
                    Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch`]);
                }
            }
        }

        property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
        property color colText: {
            if (wallpaperSafetyTriggered)
                return CF.ColorUtils.mix(Appearance.colors.colOnLayer0, Appearance.colors.colPrimary, 0.75);
            return (GlobalStates.screenLocked && shouldBlur) ? Appearance.colors.colOnLayer0 : CF.ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12));
        }
        Behavior on colText {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        function filterDuplicatePlayers(players) {
            let filtered = [];
            let used = new Set();

            for (let i = 0; i < players.length; ++i) {
                if (used.has(i))
                    continue;
                let p1 = players[i];
                let group = [i];

                // Find duplicates by trackTitle prefix
                for (let j = i + 1; j < players.length; ++j) {
                    let p2 = players[j];
                    if (p1.trackTitle && p2.trackTitle && (p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle)) || (p1.position - p2.position <= 2 && p1.length - p2.length <= 2)) {
                        group.push(j);
                    }
                }

                // Pick the one with non-empty trackArtUrl, or fallback to the first
                let chosenIdx = group.find(idx => players[idx].trackArtUrl && players[idx].trackArtUrl.length > 0);
                if (chosenIdx === undefined)
                    chosenIdx = group[0];

                filtered.push(players[chosenIdx]);
                group.forEach(idx => used.add(idx));
            }
            return filtered;
        }

        Process {
            id: cavaProc
            running: bgRoot.activePlayer.isPlaying
            onRunningChanged: {
                if (!cavaProc.running) {
                    bgRoot.visualizerPoints = [];
                }
            }
            command: ["cava", "-p", `${CF.FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config_for_background.txt`]
            stdout: SplitParser {
                onRead: data => {
                    // Parse `;`-separated values into the visualizerPoints array
                    let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                    bgRoot.visualizerPoints = points;
                }
            }
        }

        Process {
            id: cavaVUProc
            running: bgRoot.activePlayer.isPlaying
            onRunningChanged: {
                if (!cavaVUProc.running) {
                    bgRoot.currentVolume = 0;
                }
            }
            command: ["cava", "-p", `${CF.FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config_for_vu_meter.txt`]
            stdout: SplitParser {
                onRead: data => {
                    bgRoot.currentVolume = parseFloat(data.replace(";", ""));

                }
            }
        }

        // Layer props
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: (GlobalStates.screenLocked && !scaleAnim.running) ? WlrLayer.Overlay : WlrLayer.Bottom
        // WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:background"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: {
            if (!bgRoot.wallpaperSafetyTriggered || bgRoot.wallpaperIsVideo)
                return "transparent";
            return CF.ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.75);
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        onWallpaperPathChanged: {
            bgRoot.updateZoomScale();
            // Clock position gets updated after zoom scale is updated
        }

        // Wallpaper zoom scale
        function updateZoomScale() {
            getWallpaperSizeProc.path = bgRoot.wallpaperPath;
            getWallpaperSizeProc.running = true;
        }
        Process {
            id: getWallpaperSizeProc
            property string path: bgRoot.wallpaperPath
            command: ["magick", "identify", "-format", "%w %h", path]
            stdout: StdioCollector {
                id: wallpaperSizeOutputCollector
                onStreamFinished: {
                    const output = wallpaperSizeOutputCollector.text;
                    const [width, height] = output.split(" ").map(Number);
                    const [screenWidth, screenHeight] = [bgRoot.screen.width, bgRoot.screen.height];
                    bgRoot.wallpaperWidth = width;
                    bgRoot.wallpaperHeight = height;

                    // Perfect image; scale = 1
                    // Small picture; scale > 1; will zoom in the picture
                    // Big picture; scale < 1; will zoom out the picture
                    // Choose max number so every side will fit
                    bgRoot.minSuitableScale = Math.max(screenWidth / width, screenHeight / height);
                }
            }
        }

        Item {
            anchors.fill: parent

            // Wallpaper
            StyledImage {
                id: wallpaper
                visible: opacity > 0 && !blurLoader.active
                opacity: (status === Image.Ready && !bgRoot.wallpaperIsVideo) ? 1 : 0
                cache: false
                smooth: false

                property int workspaceIndex: (bgRoot.monitor.activeWorkspace?.id ?? 1) - 1
                property real middleFraction: 0.5
                property real fraction: {
                    // 0 - start of the picture
                    // 1 - end of the picture
                    if (bgRoot.totalWorkspaces <= 1) {
                        return middleFraction;
                    }
                    return Math.max(0, Math.min(1, workspaceIndex / (bgRoot.totalWorkspaces - 1)));
                }

                property real usedFractionX: {
                    let usedFraction = middleFraction;
                    if (Config.options.background.parallax.enableWorkspace && !bgRoot.verticalParallax) {
                        usedFraction = fraction;
                    }
                    if (Config.options.background.parallax.enableSidebar) {
                        let sidebarFraction = bgRoot.parallaxRation / bgRoot.workspaceChunkSize / 2;
                        usedFraction += (sidebarFraction * GlobalStates.sidebarRightOpen - sidebarFraction * GlobalStates.sidebarLeftOpen);
                    }
                    return Math.max(0, Math.min(1, usedFraction));
                }
                property real usedFractionY: {
                    let usedFraction = middleFraction;
                    if (Config.options.background.parallax.enableWorkspace && bgRoot.verticalParallax) {
                        usedFraction = fraction;
                    }
                    return Math.max(0, Math.min(1, usedFraction));
                }

                x: {
                    if (bgRoot.screen.width > width) {
                        // Center the picture
                        return (bgRoot.screen.width - width) / 2;
                    }
                    return -bgRoot.parallaxTotalPixelsX * usedFractionX;
                }
                y: {
                    if (bgRoot.screen.height > height) {
                        // Center the picture
                        return (bgRoot.screen.height - height) / 2;
                    }
                    return -bgRoot.parallaxTotalPixelsY * usedFractionY;
                }

                source: bgRoot.wallpaperSafetyTriggered ? "" : bgRoot.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                Behavior on x {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
                width: bgRoot.scaledWallpaperWidth
                height: bgRoot.scaledWallpaperHeight
            }

            Loader {
                id: blurLoader
                active: Config.options.lock.blur.enable && (GlobalStates.screenLocked || scaleAnim.running)
                anchors.fill: wallpaper
                scale: GlobalStates.screenLocked ? Config.options.lock.blur.extraZoom : 1
                Behavior on scale {
                    NumberAnimation {
                        id: scaleAnim
                        duration: 400
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                    }
                }
                sourceComponent: GaussianBlur {
                    source: wallpaper
                    radius: GlobalStates.screenLocked ? Config.options.lock.blur.radius : 0
                    samples: radius * 2 + 1

                    Rectangle {
                        opacity: GlobalStates.screenLocked ? 1 : 0
                        anchors.fill: parent
                        color: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
                    }
                }
            }

            Item {
                id: maskSource
                anchors.fill: parent
                visible: false // Used purely as a texture input for OpacityMask

                Rectangle {
                    id: maskCircle
                    anchors.centerIn: parent

                    // Maximum radius required to cover screen corners when expanded
                    readonly property real maxRadius: Math.hypot(bgRoot.width / 2, bgRoot.height / 2)

                    width: radius * 2
                    height: radius * 2
                    radius: (bgRoot.activePlayer && bgRoot.activePlayer.isPlaying) ? maxRadius : 0

                    // Smooth expand / shrink animation
                    Behavior on radius {
                        NumberAnimation {
                            duration: 500
                            easing.type: Easing.InOutCubic
                        }
                    }
                }
            }

            Item {
                id: musicWallpaperContent
                anchors.fill: parent
                visible: false // Rendered exclusively through maskSource below

                Rectangle {
                    anchors.fill: parent
                    color: bgRoot.blendedColors.colSecondaryContainerActive
                }

                SineCookie {

                    anchors.centerIn: parent
                    implicitSize: Math.max(bgRoot.width, bgRoot.height) / 1.1 + bgRoot.currentVolume / 10
                    constantlyRotate: true
                    color: blendedColors.colOnSecondaryContainer
                    rotationSpeed: 0.01
                    sides: 15
                }

                SineCookie {

                    anchors.centerIn: parent
                    implicitSize: Math.max(bgRoot.width, bgRoot.height) / 2 - bgRoot.currentVolume / 10
                    color: blendedColors.colOnPrimary
                    constantlyRotate: true
                    rotationSpeed: -0.05
                    sides: 7
                }

                StyledImage {
                    id: musicArtImage
                    visible: false // Keep hidden so only the masked output renders
                    anchors.centerIn: parent

                    source: bgRoot.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true

                    height: bgRoot.scaledWallpaperHeight / 3 + bgRoot.currentVolume / 10
                    width: height
                }

                SineCookie {
                    id: musicArtImageMask
                    visible: false // Keep hidden so it only acts as an alpha texture
                    anchors.centerIn: parent
                    implicitSize: musicArtImage.implicitHeight + bgRoot.currentVolume / 10

                    constantlyRotate: true
                    rotationSpeed: 0.1
                    sides: 5
                    opacity: 0.5
                }

                OpacityMask {
                    anchors.fill: musicArtImage
                    source: musicArtImage
                    maskSource: musicArtImageMask
                }
            }

            OpacityMask {
                anchors.fill: parent
                source: musicWallpaperContent
                maskSource: maskSource
            }

            // Still hard coded enabled for now
            // TODO: Add config entry and Settings switch to toggle/configure visualizer
            Repeater {
                model: ScriptModel { values: bgRoot.meaningfulPlayers }
                delegate: WaveVisualizer {
                    required property MprisPlayer modelData

                    // Anchor to the sides, but handle vertical positioning with 'y'
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: bgRoot.screen.height * 0.3

                    live: bgRoot.visible && modelData.playbackStatus === MprisPlaybackStatus.Playing
                    points: bgRoot.visualizerPoints
                    maxVisualizerValue: bgRoot.maxVisualizerValue
                    smoothing: bgRoot.visualizerSmoothing

                    transparency: 0.4
                    Behavior on opacity { NumberAnimation { duration: 500 } }
                }
            }
        }
    }
}
