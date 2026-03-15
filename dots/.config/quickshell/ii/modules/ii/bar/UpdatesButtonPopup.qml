import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root




    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 4

        StyledPopupHeaderRow {
            icon: "update"
            label: Translation.tr("Updates")
        }

        StyledText {
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.Wrap
            color: Appearance.colors.colOnSurfaceVariant
            text: "Updateable Packages: " + Updates.count
        }

  
    }
}
