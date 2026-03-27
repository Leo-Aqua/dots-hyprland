import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets



RippleButtonWithIcon {
    id: update
    materialIcon: "update"
    mainText: ""
    implicitHeight: Appearance.sizes.baseBarHeight - 8  // matches BarGroup pill height (40 - 4top - 4bottom)
    

    color: Updates.updateStronglyAdvised ? Appearance.m3colors.m3error : Appearance.colors.colOnLayer2

    MouseArea {
        id: updatepopup
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: {
            if (mouse.button === Qt.RightButton) { 
                Quickshell.execDetached(["notify-send", "-a", "Quickshell", "Updater", "Searching for updates..."]);
                Updates.refresh();
            } else if (mouse.button === Qt.LeftButton) {
                Quickshell.execDetached(["bash", "-c", Config.options.apps.update]);
            }
        }
        UpdatesButtonPopup {
            hoverTarget: updatepopup
        }
    }
}