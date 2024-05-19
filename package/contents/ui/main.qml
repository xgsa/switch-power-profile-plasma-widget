import QtQuick 2.12

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0

Item {
    id: root

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.ConfigurableBackground


    property QtObject pmSource: PlasmaCore.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: sources
        onSourceAdded: source => {
            disconnectSource(source);
            connectSource(source);
        }
        onSourceRemoved: source => {
            disconnectSource(source);
        }
    }

    readonly property string actuallyActiveProfile: pmSource.data["Power Profiles"] ? (pmSource.data["Power Profiles"]["Current Profile"] || "") : ""
    readonly property string iconsPath: Qt.resolvedUrl("..") + "/icons/"

    Plasmoid.compactRepresentation: MouseArea {
        activeFocusOnTab: true
        hoverEnabled: true

        PlasmaCore.IconItem {
            anchors.fill: parent
            source: {
                // console.log("Mode: " + actuallyActiveProfile)
                const known_profile = ["power-saver", "performance", "balanced"].includes(actuallyActiveProfile)
                return iconsPath + (known_profile ? actuallyActiveProfile : "unknown-mode" ) + ".svg"
            }
            active: parent.containsMouse
        }
        onClicked: {
            const service = pmSource.serviceForSource("PowerDevil");
            const op = service.operationDescription("setPowerProfile");
            op.profile = actuallyActiveProfile === "performance" ? "power-saver" : "performance";
    
            const job = service.startOperationCall(op);
            job.finished.connect(job => {
                // TODO: Handle operation result and show user the result (how?)
                // dialogItem.activeProfile = Qt.binding(() => actuallyActiveProfile);
                // if (!job.result) {
                //     powerProfileError.text = i18n("Failed to activate %1 mode", profile);
                //     powerProfileError.sendEvent();
                //     return;
                // }
            });
        }
    }

    Plasmoid.toolTipMainText: i18n("Active Power Profile")
    Plasmoid.toolTipSubText: {
        const mode_names = {
            "power-saver": i18n("Power Save"),
            "balanced": i18n("Balanced"),
            "performance": i18n("Performance"),
        }
        return (mode_names[actuallyActiveProfile] || "Unknown")
    }
}
