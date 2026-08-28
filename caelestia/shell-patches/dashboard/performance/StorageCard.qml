import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    // Storage.disks (the dropdown below) enumerates whole physical block
    // devices via the compiled Storage service, not individual mountpoints -
    // on a dual-boot machine that means "nvme0n1" aggregates Windows +
    // Fedora usage together, with no way to see just Fedora's own space.
    // Can't add a real entry to that compiled list, so this toggle computes
    // /home's usage independently via `df` instead.
    property bool fedoraOnly: false
    property double fedoraUsedKib: 0
    property double fedoraTotalKib: 0

    readonly property color accent: Colours.palette.m3secondary
    readonly property real percentage: root.fedoraOnly ? (root.fedoraTotalKib > 0 ? root.fedoraUsedKib / root.fedoraTotalKib : 0) : (Storage.primaryDisk?.perc ?? 0)

    Process {
        id: fedoraDf
        command: ["df", "--output=used,size", "-B1024", "/home"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                if (lines.length < 2) return;
                const parts = lines[1].trim().split(/\s+/);
                if (parts.length < 2) return;
                root.fedoraUsedKib = parseFloat(parts[0]);
                root.fedoraTotalKib = parseFloat(parts[1]);
            }
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: fedoraDf.running = true
    }

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraExtraLarge

    implicitWidth: layout.implicitWidth + layout.anchors.margins * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    ServiceRef {
        service: Storage
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.extraLarge
        spacing: 0

        RowLayout {
            id: row

            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.large

            CircularProgress {
                fgColour: root.accent
                value: root.percentage
                implicitSize: usageColumn.implicitHeight + thickness + Tokens.padding.large * 2
                startAngle: -225
                sweepAngle: 270

                Behavior on clampedVal {
                    Anim {}
                }

                ColumnLayout {
                    id: usageColumn

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hard_drive"
                        color: root.accent
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Math.round(root.percentage * 100) + "%"
                        font: Tokens.font.title.builders.large.width(90).build()
                        color: root.accent
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Used")
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            ColumnLayout {
                Layout.minimumWidth: Tokens.sizes.dashboard.perfStorageTextWidth
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: root.fedoraOnly ? qsTr("Fedora") : qsTr("Storage")
                    font: Tokens.font.title.medium
                }

                StyledText {
                    text: {
                        if (root.fedoraOnly) {
                            if (root.fedoraTotalKib === 0)
                                return qsTr("Loading...");
                            const fmt = UsageFmt.formatKib(root.fedoraUsedKib, root.fedoraTotalKib);
                            return `${+fmt.value.toFixed(1)} / ${+fmt.total.toFixed(1)} ${fmt.unit}`;
                        }

                        if (!Storage.primaryDisk)
                            return qsTr("No disks detected");

                        const fmt = UsageFmt.formatKib(Storage.primaryDisk.used, Storage.primaryDisk.total);
                        return `${+fmt.value.toFixed(1)} / ${+fmt.total.toFixed(1)} ${fmt.unit}`;
                    }
                    font: Tokens.font.body.large
                    color: root.accent
                }
            }
        }

        SplitButton {
            Layout.alignment: Qt.AlignHCenter

            type: SplitButton.Tonal
            disabled: !Storage.disks.length
            fallbackIcon: "storage"
            fallbackText: qsTr("No disks")
            menuOnTop: true
            minLeftWidth: row.implicitWidth * 0.6

            menuItems: [...disks.instances, fedoraItem]
            active: root.fedoraOnly ? fedoraItem : (menuItems.find(m => m.modelData === Storage.primaryDisk) ?? menuItems[0] ?? null)
            menu.onItemSelected: item => {
                if (item === fedoraItem) {
                    root.fedoraOnly = true;
                } else {
                    root.fedoraOnly = false;
                    Storage.manualPrimaryDisk = (item as DiskItem).modelData;
                }
            }

            Variants {
                id: disks

                model: Storage.disks

                DiskItem {}
            }

            // Not a real Storage.disks entry (see the comment at the top of
            // this file for why) - a separate static menu item that toggles
            // root.fedoraOnly instead of Storage.manualPrimaryDisk.
            MenuItem {
                id: fedoraItem

                icon: root.fedoraOnly ? "check" : ""
                text: qsTr("Fedora")
                activeIcon: "storage"
            }
        }
    }

    component DiskItem: MenuItem {
        required property var modelData

        icon: (!root.fedoraOnly && modelData === Storage.primaryDisk) ? "check" : ""
        text: modelData.mount
        activeIcon: "storage"
    }
}
