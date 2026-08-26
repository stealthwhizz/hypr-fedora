import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

StyledClippingRect {
    id: root

    property real animPerc: UPower.displayDevice.percentage
    // UPower.displayDevice is a synthesised aggregate that doesn't forward
    // the real battery's health/capacity data (confirmed live: its Capacity
    // stays 0 over D-Bus even though the real battery_BAT0 device reports
    // 100) - health has to be read from the actual physical battery device.
    readonly property var laptopBattery: {
        const devices = UPower.devices.values;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].isLaptopBattery) return devices[i];
        }
        return null;
    }

    color: Colours.palette.m3secondaryContainer
    radius: Tokens.rounding.large

    implicitWidth: Config.dashboard.performance.showCpu || (Config.dashboard.performance.showGpu && Gpu.type !== Gpu.None) || Config.dashboard.performance.showStorage || Config.dashboard.performance.showMemory ? Tokens.sizes.dashboard.perfBattWidth : Tokens.sizes.dashboard.perfBattWidthSingle
    implicitHeight: Tokens.sizes.dashboard.perfBattHeight

    Behavior on animPerc {
        Anim {}
    }

    Contents {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium

        accentColour: Colours.palette.m3primary
        textColour: Colours.palette.m3onSurface
        subTextColour: Colours.palette.m3onSurfaceVariant
    }

    StyledRect {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: parent.height * root.animPerc

        color: Colours.palette.m3secondary
        radius: Tokens.rounding.extraSmall
        clip: true

        Contents {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: layout.anchors.margins
            height: layout.height

            accentColour: Colours.palette.m3primaryContainer
            textColour: Colours.palette.m3onSecondary
            subTextColour: Colours.palette.m3secondaryContainer
        }
    }

    component Contents: ColumnLayout {
        id: contents

        required property color accentColour
        required property color textColour
        required property color subTextColour
        readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)

        spacing: 0

        MaterialIcon {
            Layout.leftMargin: -Tokens.padding.extraSmall
            text: "battery_full"
            color: contents.accentColour
            fontStyle: Tokens.font.icon.large
        }

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Battery")
            color: contents.textColour
            font: Tokens.font.body.medium
        }

        Item {
            Layout.fillHeight: true
        }

        StyledText {
            Layout.alignment: Qt.AlignRight
            text: {
                if (UPower.displayDevice.state === UPowerDeviceState.FullyCharged)
                    return qsTr("Full");

                if (contents.charging)
                    return qsTr("Charging");

                const s = UPower.displayDevice.timeToEmpty;
                if (s === 0)
                    return qsTr("...");

                const hr = Math.floor(s / 3600);
                const min = Math.floor((s % 3600) / 60);
                if (hr > 0)
                    return `${hr}h ${min}m`;

                return `${min}m`;
            }
            color: contents.subTextColour
            font: Tokens.font.body.small
            animate: true
        }

        StyledText {
            visible: root.laptopBattery !== null && root.laptopBattery.healthSupported
            Layout.alignment: Qt.AlignRight
            // healthPercentage is already 0-100 on the real device object
            // (unlike UPower.displayDevice.percentage, which is a 0-1
            // fraction) - confirmed live, an earlier *100 here showed 10000%.
            text: root.laptopBattery ? qsTr("Health %1%").arg(Math.round(root.laptopBattery.healthPercentage)) : ""
            color: contents.subTextColour
            font: Tokens.font.body.small
            animate: true
        }

        RowLayout {
            Layout.topMargin: -Tokens.padding.extraSmall
            Layout.bottomMargin: -Tokens.padding.small
            Layout.rightMargin: -Tokens.padding.extraSmall
            Layout.alignment: Qt.AlignRight
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                text: "bolt"
                color: contents.accentColour
                fontStyle: Tokens.font.icon.large
                fill: 1

                scale: contents.charging ? 1 : 0
                opacity: contents.charging ? 1 : 0

                Behavior on scale {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.FastEffects
                    }
                }
            }

            StyledText {
                text: `${Math.round(UPower.displayDevice.percentage * 100)}%`
                color: contents.accentColour
                font: Tokens.font.headline.medium
            }
        }
    }
}
