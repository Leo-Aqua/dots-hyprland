import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets

MouseArea {
    id: root

    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        FadeLoader {
            // 1. Pass the exact same logic into the 'shown' prop
            //shown: !resourceMemory.shown && !resourceSwap.shown && !resourceCPU.shown && !resourceGPU.shown

            // 2. Define positioning or anchors on the Loader itself, not inside the component
            // (e.g., anchoring it to your parent layout or bar)
            Layout.alignment: Qt.AlignLeft
            Layout.rightMargin: 4
            // 3. Provide the component inside the FadeLoader using sourceComponent
            sourceComponent: MaterialSymbol {
                text: "dns"
            }
        }

        Resource {
            id: resourceMemory
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            absoluteValue: Config.options.bar.resources.memoryInGB ? root.formatKB(ResourceUsage.memoryUsed) :
                                                                     undefined
            shown: Config.options.bar.resources.showMemory && ((Config.options.bar.resources.alwaysShowMemory || percentage
                                                                > Config.options.bar.resources.showMemoryThreshold
                                                                / 100) && (MprisController.activePlayer
                                                                           ?.trackTitle == null)
                                                               || root.alwaysShowAllResources)
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        Resource {
            id: resourceSwap
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            absoluteValue: Config.options.bar.resources.memoryInGB ? root.formatKB(ResourceUsage.swapUsed) :
                                                                     undefined

            shown: Config.options.bar.resources.showSwap && ((Config.options.bar.resources.alwaysShowSwap || percentage
                                                              > Config.options.bar.resources.showSwapThreshold
                                                              / 100) && (MprisController.activePlayer
                                                                         ?.trackTitle == null)
                                                             || root.alwaysShowAllResources)

            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }

        Resource {
            id: resourceCPU
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.showCPU && ((Config.options.bar.resources.alwaysShowCpu || percentage
                                                             > Config.options.bar.resources.showCPUThreshold
                                                             / 100) && (MprisController.activePlayer
                                                                        ?.trackTitle == null)
                                                            || root.alwaysShowAllResources)
            Layout.leftMargin: shown ? 6 : 0

            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

        Resource {
            id: resourceGPU
            iconName: "empty_dashboard"
            percentage: (Config.options.bar.resources.gpuLayout == 0
                         || Config.options.bar.resources.gpuLayout == 2) ? GpuUsage.dGpuUsage :
                                                                           GpuUsage.iGpuUsage
            shown: (Config.options.bar.resources.gpu.bar.showDGpu
                    || Config.options.bar.resources.bar.gpu.showIGpu) && (((GpuUsage.dGpuAvailable && (
                                                                                Config.options.bar.resources.gpuLayout
                                                                                == 0 || Config.options.bar.resources.gpuLayout
                                                                                == 2)) || (
                                                                               GpuUsage.iGpuAvailable && (
                                                                                   Config.options.bar.resources.gpuLayout
                                                                                   == 1))) && ((
                                                                                                   Config.options.bar.resources.alwaysShowGpu
                                                                                                   || percentage
                                                                                                   > Config.options.bar.resources.showGPUThreshold
                                                                                                   / 100) && (
                                                                                                   MprisController.activePlayer
                                                                                                   ?.trackTitle
                                                                                                   == null)
                                                                                               || root.alwaysShowAllResources))
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.gpuWarningThreshold
        }
    }

    ResourcesPopup {
        hoverTarget: root
    }
}
