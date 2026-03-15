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
        onClicked: {
            Quickshell.execDetached(["bash", "-c", Config.options.apps.update]);
        }
        UpdatesButtonPopup {
            hoverTarget: updatepopup
        }
    }
}