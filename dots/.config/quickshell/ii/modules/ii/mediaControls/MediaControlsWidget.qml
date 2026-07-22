pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    // Configuration / Sizing Properties
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property var realPlayers: MprisController.players
    readonly property var meaningfulPlayers: filterDuplicatePlayers(realPlayers)

    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight
    property real popupRounding: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
    property list<real> visualizerPoints: []
    property bool disableVisualizer: false
    property bool noPlaceholder: false

    // Size implicit bounds to match contents
    implicitWidth: playerColumnLayout.implicitWidth
    implicitHeight: playerColumnLayout.implicitHeight

    // Deduplicate MPRIS players
    function filterDuplicatePlayers(players) {
        let filtered = [];
        let used = new Set();

        for (let i = 0; i < players.length; ++i) {
            if (used.has(i))
                continue;
            let p1 = players[i];
            let group = [i];

            for (let j = i + 1; j < players.length; ++j) {
                let p2 = players[j];
                if ((p1.trackTitle && p2.trackTitle && (p1.trackTitle.includes(p2.trackTitle)
                                                        || p2.trackTitle.includes(p1.trackTitle))) || (
                            Math.abs(p1.position - p2.position) <= 2 && Math.abs(p1.length - p2.length)
                            <= 2)) {
                    group.push(j);
                }
            }

            let chosenIdx = group.find(idx => players[idx].trackArtUrl && players[idx].trackArtUrl.length
                                              > 0);
            if (chosenIdx === undefined)
                chosenIdx = group[0];

            filtered.push(players[chosenIdx]);
            group.forEach(idx => used.add(idx));
        }
        return filtered;
    }

    // CAVA Audio Visualizer Process
    Process {
        id: cavaProc
        running: root.visible && !disableVisualizer
        onRunningChanged: {
            if (!cavaProc.running) {
                root.visualizerPoints = [];
            }
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)
            }/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    // Layout Content
    ColumnLayout {
        id: playerColumnLayout
        anchors.fill: parent
        spacing: -Appearance.sizes.elevationMargin

        // Dynamic Player List
        Repeater {
            model: ScriptModel {
                values: root.meaningfulPlayers
            }

            delegate: PlayerControl {
                required property MprisPlayer modelData
                player: modelData
                visualizerPoints: root.visualizerPoints
                implicitWidth: root.widgetWidth
                implicitHeight: root.widgetHeight
                radius: root.popupRounding
            }
        }

        // Placeholder when no active media is playing
        Item {
            id: emptyState
            visible: root.meaningfulPlayers.length === 0 && !noPlaceholder

            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: Appearance.sizes.hyprlandGapsOut
            Layout.rightMargin: Appearance.sizes.hyprlandGapsOut

            implicitWidth: placeholderBackground.implicitWidth + Appearance.sizes.elevationMargin
            implicitHeight: placeholderBackground.implicitHeight + Appearance.sizes.elevationMargin

            StyledRectangularShadow {
                target: placeholderBackground
            }

            Rectangle {
                id: placeholderBackground
                anchors.centerIn: parent
                color: Appearance.colors.colLayer0
                radius: root.popupRounding
                property real padding: 20
                implicitWidth: placeholderLayout.implicitWidth + padding * 2
                implicitHeight: placeholderLayout.implicitHeight + padding * 2

                ColumnLayout {
                    id: placeholderLayout
                    anchors.centerIn: parent

                    StyledText {
                        text: Translation.tr("No active player")
                        font.pixelSize: Appearance.font.pixelSize.large
                    }
                    StyledText {
                        color: Appearance.colors.colSubtext
                        text: Translation.tr(
                                  "Make sure your player has MPRIS support\nor try turning off duplicate player filtering")
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }
            }
        }
    }
}
